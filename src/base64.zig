const std = @import("std");

pub const DecodeError = error{
    InvalidCharacter,
    InvalidPadding,
    TruncatedInput,
};

pub const Variant = enum { standard, url_safe };

pub const EncodeOptions = struct {
    variant: Variant = .standard,
    padding: bool = true,
};

pub const DecodeOptions = struct {
    variant: Variant = .standard,
    ignore_whitespace: bool = true,
};

fn alphabetFor(variant: Variant) [64]u8 {
    return switch (variant) {
        .standard => "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".*,
        .url_safe => "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_".*,
    };
}

fn makeReverseTable(variant: Variant) [256]u8 {
    var table: [256]u8 = .{255} ** 256; // 255 as invalid marker
    const alpha = alphabetFor(variant);
    var i: usize = 0;
    while (i < 64) : (i += 1) table[@as(usize, alpha[i])] = @intCast(i);
    return table;
}

pub fn encodedLen(input_len: usize, padding: bool) usize {
    const full = input_len / 3;
    const rem = input_len % 3;
    if (padding) {
        return (full * 4) + (if (rem == 0) @as(usize, 0) else @as(usize, 4));
    } else {
        return (full * 4) + (if (rem == 0) @as(usize, 0) else rem + 1);
    }
}

pub fn encodeAlloc(alloc: std.mem.Allocator, input: []const u8, opts: EncodeOptions) ![]u8 {
    const out_len = encodedLen(input.len, opts.padding);
    const out = try alloc.alloc(u8, out_len);
    errdefer alloc.free(out);
    const written = try encodeInto(out, input, opts);
    std.debug.assert(written == out_len);
    return out;
}

pub fn encodeInto(out: []u8, input: []const u8, opts: EncodeOptions) !usize {
    const alpha = alphabetFor(opts.variant);
    var i: usize = 0;
    var o: usize = 0;
    while (i + 3 <= input.len) : (i += 3) {
        const n = (@as(u32, input[i]) << 16) | (@as(u32, input[i + 1]) << 8) | @as(u32, input[i + 2]);
        out[o] = alpha[(n >> 18) & 0x3F];
        out[o + 1] = alpha[(n >> 12) & 0x3F];
        out[o + 2] = alpha[(n >> 6) & 0x3F];
        out[o + 3] = alpha[n & 0x3F];
        o += 4;
    }
    const rem = input.len - i;
    if (rem == 1) {
        const n = @as(u32, input[i]) << 16;
        out[o] = alpha[(n >> 18) & 0x3F];
        out[o + 1] = alpha[(n >> 12) & 0x3F];
        if (opts.padding) {
            out[o + 2] = '=';
            out[o + 3] = '=';
            o += 4;
        } else {
            out[o + 2] = alpha[(n >> 6) & 0x3F];
            o += 3;
        }
    } else if (rem == 2) {
        const n = (@as(u32, input[i]) << 16) | (@as(u32, input[i + 1]) << 8);
        out[o] = alpha[(n >> 18) & 0x3F];
        out[o + 1] = alpha[(n >> 12) & 0x3F];
        out[o + 2] = alpha[(n >> 6) & 0x3F];
        if (opts.padding) {
            out[o + 3] = '=';
            o += 4;
        } else {
            o += 3;
        }
    }
    return o;
}

fn isWhitespace(c: u8) bool {
    return c == ' ' or c == '\n' or c == '\r' or c == '\t' or c == '\x0b' or c == '\x0c';
}

pub fn decodedLenEstimate(input: []const u8, opts: DecodeOptions) !usize {
    // Count meaningful base64 chars ignoring whitespace; detect padding to refine.
    var count: usize = 0;
    var pad: usize = 0;
    for (input) |c| {
        if (opts.ignore_whitespace and isWhitespace(c)) continue;
        if (c == '=') {
            pad += 1;
        } else {
            count += 1;
        }
    }
    if (pad > 2) return DecodeError.InvalidPadding;
    // Every 4 chars -> 3 bytes, minus padding
    const quads = (count + pad + 3) / 4; // ceil-ish
    var bytes = quads * 3;
    if (pad > 0) bytes -= pad;
    return bytes;
}

pub fn decodeAlloc(alloc: std.mem.Allocator, input: []const u8, opts: DecodeOptions) ![]u8 {
    const est = try decodedLenEstimate(input, opts);
    var out = try alloc.alloc(u8, est);
    errdefer alloc.free(out);
    const written = try decodeInto(out, input, opts);
    if (written < out.len) {
        return out[0..written];
    }
    return out;
}

pub fn decodeInto(out: []u8, input: []const u8, opts: DecodeOptions) !usize {
    const rev = makeReverseTable(opts.variant);
    var quad: [4]u8 = undefined;
    var qi: usize = 0;
    var o: usize = 0;

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        const c = input[i];
        if (opts.ignore_whitespace and isWhitespace(c)) continue;
        if (c == '=') {
            // Fill remaining quad with '=' and break appropriately
            if (qi == 2) {
                // xx== → one output byte
                quad[2] = '=';
                quad[3] = '=';
            } else if (qi == 3) {
                // xxx= → two output bytes
                quad[3] = '=';
            } else {
                return DecodeError.InvalidPadding;
            }
            // Process final quad now
            const a = rev[quad[0]]; if (a == 255) return DecodeError.InvalidCharacter;
            const b = rev[quad[1]]; if (b == 255) return DecodeError.InvalidCharacter;
            const n_ab = (@as(u32, a) << 18) | (@as(u32, b) << 12);
            if (quad[2] == '=') {
                // one byte
                if (o >= out.len) return DecodeError.TruncatedInput;
                out[o] = @intCast((n_ab >> 16) & 0xFF);
                o += 1;
                // any trailing non-whitespace chars are invalid
                // ensure remaining meaningful input is whitespace only
                while (i + 1 < input.len) : (i += 1) {
                    const c2 = input[i + 1];
                    if (opts.ignore_whitespace and isWhitespace(c2)) continue;
                    if (c2 == '=') continue; // allow remaining padding chars only
                    return DecodeError.InvalidPadding;
                }
                return o;
            } else {
                const c_val = rev[quad[2]]; if (c_val == 255) return DecodeError.InvalidCharacter;
                const n_abc = n_ab | (@as(u32, c_val) << 6);
                if (quad[3] == '=') {
                    if (o + 1 >= out.len) return DecodeError.TruncatedInput;
                    out[o] = @intCast((n_abc >> 16) & 0xFF);
                    out[o + 1] = @intCast((n_abc >> 8) & 0xFF);
                    o += 2;
                    while (i + 1 < input.len) : (i += 1) {
                        const c2 = input[i + 1];
                        if (opts.ignore_whitespace and isWhitespace(c2)) continue;
                        // after xxx=, no further base64 chars or '=' allowed
                        return DecodeError.InvalidPadding;
                    }
                    return o;
                } else {
                    // shouldn't see '=' in quad[3] here
                    unreachable;
                }
            }
        } else {
            const r = rev[c];
            if (r == 255) return DecodeError.InvalidCharacter;
            quad[qi] = c;
            qi += 1;
            if (qi == 4) {
                const a = rev[quad[0]];
                const b = rev[quad[1]];
                const c3 = rev[quad[2]];
                const d = rev[quad[3]];
                const n = (@as(u32, a) << 18) | (@as(u32, b) << 12) | (@as(u32, c3) << 6) | @as(u32, d);
                if (o + 3 > out.len) return DecodeError.TruncatedInput;
                out[o] = @intCast((n >> 16) & 0xFF);
                out[o + 1] = @intCast((n >> 8) & 0xFF);
                out[o + 2] = @intCast(n & 0xFF);
                o += 3;
                qi = 0;
            }
        }
    }

    if (qi != 0) return DecodeError.TruncatedInput;
    return o;
}

pub fn encodeStream(reader: std.fs.File, writer: std.fs.File, opts: EncodeOptions) !void {
    const alpha = alphabetFor(opts.variant);
    var buf: [4096]u8 = undefined;
    var carry: [3]u8 = .{0} ** 3;
    var carry_len: usize = 0;
    while (true) {
        const n = try reader.read(buf[0..]);
        if (n == 0) break;
        var src = buf[0..n];
        if (carry_len != 0) {
            var tmp: [4096 + 3]u8 = undefined;
            @memcpy(tmp[0..carry_len], carry[0..carry_len]);
            @memcpy(tmp[carry_len..][0..src.len], src);
            src = tmp[0 .. carry_len + src.len];
            carry_len = 0;
        }
        const trip = src.len - (src.len % 3);
        var i: usize = 0;
        while (i < trip) : (i += 3) {
            const n24 = (@as(u32, src[i]) << 16) | (@as(u32, src[i + 1]) << 8) | @as(u32, src[i + 2]);
            var out4: [4]u8 = .{
                alpha[(n24 >> 18) & 0x3F],
                alpha[(n24 >> 12) & 0x3F],
                alpha[(n24 >> 6) & 0x3F],
                alpha[n24 & 0x3F],
            };
            _ = try writer.writeAll(out4[0..]);
        }
        const rem = src.len - trip;
        if (rem != 0) {
            carry_len = rem;
            @memcpy(carry[0..rem], src[trip..][0..rem]);
        }
    }
    if (carry_len == 1) {
        const n24 = @as(u32, carry[0]) << 16;
        var out = [_]u8{ alpha[(n24 >> 18) & 0x3F], alpha[(n24 >> 12) & 0x3F] };
        _ = try writer.writeAll(out[0..]);
        if (opts.padding) {
            _ = try writer.writeAll("==");
        } else {
            const more = [_]u8{ alpha[(n24 >> 6) & 0x3F] };
            _ = try writer.writeAll(more[0..]);
        }
    } else if (carry_len == 2) {
        const n24 = (@as(u32, carry[0]) << 16) | (@as(u32, carry[1]) << 8);
        var out = [_]u8{ alpha[(n24 >> 18) & 0x3F], alpha[(n24 >> 12) & 0x3F], alpha[(n24 >> 6) & 0x3F] };
        _ = try writer.writeAll(out[0..]);
        if (opts.padding) {
            _ = try writer.writeAll("=");
        }
    }
}

pub fn decodeStream(reader: std.fs.File, writer: std.fs.File, opts: DecodeOptions) !void {
    const rev = makeReverseTable(opts.variant);
    var buf: [4096]u8 = undefined;
    var quad: [4]u8 = undefined;
    var qi: usize = 0;
    while (true) {
        const n = try reader.read(buf[0..]);
        if (n == 0) break;
        for (buf[0..n]) |c| {
            if (opts.ignore_whitespace and isWhitespace(c)) continue;
            if (c == '=') {
                if (qi == 2) {
                    quad[2] = '='; quad[3] = '=';
                    const a = rev[quad[0]]; if (a == 255) return DecodeError.InvalidCharacter;
                    const b = rev[quad[1]]; if (b == 255) return DecodeError.InvalidCharacter;
                    const n_ab = (@as(u32, a) << 18) | (@as(u32, b) << 12);
                    const outb = [_]u8{ @intCast((n_ab >> 16) & 0xFF) };
                    _ = try writer.writeAll(outb[0..]);
                    qi = 0;
                } else if (qi == 3) {
                    quad[3] = '=';
                    const a = rev[quad[0]]; if (a == 255) return DecodeError.InvalidCharacter;
                    const b = rev[quad[1]]; if (b == 255) return DecodeError.InvalidCharacter;
                    const c_val = rev[quad[2]]; if (c_val == 255) return DecodeError.InvalidCharacter;
                    const n_abc = (@as(u32, a) << 18) | (@as(u32, b) << 12) | (@as(u32, c_val) << 6);
                    const outb = [_]u8{ @intCast((n_abc >> 16) & 0xFF), @intCast((n_abc >> 8) & 0xFF) };
                    _ = try writer.writeAll(outb[0..]);
                    qi = 0;
                } else {
                    return DecodeError.InvalidPadding;
                }
            } else {
                const r = rev[c];
                if (r == 255) return DecodeError.InvalidCharacter;
                quad[qi] = c;
                qi += 1;
                if (qi == 4) {
                    const a = rev[quad[0]];
                    const b = rev[quad[1]];
                    const c3 = rev[quad[2]];
                    const d = rev[quad[3]];
                    const n24 = (@as(u32, a) << 18) | (@as(u32, b) << 12) | (@as(u32, c3) << 6) | @as(u32, d);
                    const outb = [_]u8{ @intCast((n24 >> 16) & 0xFF), @intCast((n24 >> 8) & 0xFF), @intCast(n24 & 0xFF) };
                    _ = try writer.writeAll(outb[0..]);
                    qi = 0;
                }
            }
        }
    }

    if (qi == 1) return DecodeError.TruncatedInput;
    if (qi == 2) {
        const a = rev[quad[0]]; const b = rev[quad[1]];
        if (a == 255 or b == 255) return DecodeError.InvalidCharacter;
        const n_ab = (@as(u32, a) << 18) | (@as(u32, b) << 12);
        const outb = [_]u8{ @intCast((n_ab >> 16) & 0xFF) };
        _ = try writer.writeAll(outb[0..]);
    } else if (qi == 3) {
        const a = rev[quad[0]]; const b = rev[quad[1]]; const c_val = rev[quad[2]];
        if (a == 255 or b == 255 or c_val == 255) return DecodeError.InvalidCharacter;
        const n_abc = (@as(u32, a) << 18) | (@as(u32, b) << 12) | (@as(u32, c_val) << 6);
        const outb = [_]u8{ @intCast((n_abc >> 16) & 0xFF), @intCast((n_abc >> 8) & 0xFF) };
        _ = try writer.writeAll(outb[0..]);
    }
}test "RFC 4648 vectors" {
    const alloc = std.testing.allocator;
    const cases = [_][2][]const u8{
        .{ "", "" },
        .{ "f", "Zg==" },
        .{ "fo", "Zm8=" },
        .{ "foo", "Zm9v" },
        .{ "foob", "Zm9vYg==" },
        .{ "fooba", "Zm9vYmE=" },
        .{ "foobar", "Zm9vYmFy" },
    };
    for (cases) |pair| {
        const enc = try encodeAlloc(alloc, pair[0], .{});
        defer alloc.free(enc);
        try std.testing.expectEqualStrings(pair[1], enc);
        const dec = try decodeAlloc(alloc, pair[1], .{});
        defer alloc.free(dec);
        try std.testing.expectEqualStrings(pair[0], dec);
    }
}

test "whitespace is ignored in decode" {
    const alloc = std.testing.allocator;
    const spaced = "Z m9v\nYmFy\t";
    const dec = try decodeAlloc(alloc, spaced, .{ .ignore_whitespace = true });
    defer alloc.free(dec);
    try std.testing.expectEqualStrings("foobar", dec);
}

test "truncated input error" {
    const alloc = std.testing.allocator;
    try std.testing.expectError(DecodeError.TruncatedInput, decodeAlloc(alloc, "Zg", .{}));
}
