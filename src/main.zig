const std = @import("std");
const base64 = @import("base64.zig");

const Mode = enum { encode, decode };

const Cli = struct {
    mode: Mode = .encode,
    url_safe: bool = false,
    no_padding: bool = false,
    input_path: ?[]const u8 = null,
    output_path: ?[]const u8 = null,
};

fn printUsage() void {
    std.debug.print("Usage: zig-base64 [encode|decode] [--url-safe] [--no-padding] [--input <path>] [--output <path>]\n", .{});
}

fn parseArgs(alloc: std.mem.Allocator, it: *std.process.ArgIterator) !Cli {
    var cli = Cli{};
    // skip program name already consumed by caller
    while (it.next()) |arg| {
        if (std.mem.eql(u8, arg, "encode")) {
            cli.mode = .encode;
        } else if (std.mem.eql(u8, arg, "decode") or std.mem.eql(u8, arg, "--decode")) {
            cli.mode = .decode;
        } else if (std.mem.eql(u8, arg, "--url-safe")) {
            cli.url_safe = true;
        } else if (std.mem.eql(u8, arg, "--no-padding")) {
            cli.no_padding = true;
        } else if (std.mem.eql(u8, arg, "--input")) {
            const path = it.next() orelse return error.MissingValue;
            cli.input_path = try alloc.dupe(u8, path);
        } else if (std.mem.eql(u8, arg, "--output")) {
            const path = it.next() orelse return error.MissingValue;
            cli.output_path = try alloc.dupe(u8, path);
        } else if (std.mem.startsWith(u8, arg, "-")) {
            std.debug.print("Unknown option: {s}\n", .{arg});
            return error.InvalidArgument;
        } else {
            // positional could be mode; if not recognized, error
            std.debug.print("Unknown positional: {s}\n", .{arg});
            return error.InvalidArgument;
        }
    }
    return cli;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var it = try std.process.argsWithAllocator(alloc);
    defer it.deinit();
    _ = it.next(); // skip argv[0]

    var cli: Cli = undefined;
    cli = parseArgs(alloc, &it) catch |e| {
        printUsage();
        std.log.err("{s}", .{@errorName(e)});
        std.process.exit(1);
    };

    var fin: ?std.fs.File = null;
    var fout: ?std.fs.File = null;
    defer if (fin) |*f| if (cli.input_path != null) f.close();
    defer if (fout) |*f| if (cli.output_path != null) f.close();

    if (cli.input_path) |path| {
        fin = std.fs.cwd().openFile(path, .{}) catch |e| {
            std.log.err("input open error: {s}", .{@errorName(e)});
            std.process.exit(2);
        };
    } else {
        fin = std.fs.File{ .handle = std.os.windows.peb().ProcessParameters.hStdInput };
    }

    if (cli.output_path) |path| {
        fout = std.fs.cwd().createFile(path, .{ .truncate = true }) catch |e| {
            std.log.err("output open error: {s}", .{@errorName(e)});
            std.process.exit(2);
        };
    } else {
        fout = std.fs.File{ .handle = std.os.windows.peb().ProcessParameters.hStdOutput };
    }

    if (cli.mode == .encode) {
        const opts = base64.EncodeOptions{ .variant = if (cli.url_safe) .url_safe else .standard, .padding = !cli.no_padding };
        base64.encodeStream(fin.?, fout.?, opts) catch |e| {
            std.log.err("encode error: {s}", .{@errorName(e)});
            std.process.exit(3);
        };
        // newline for human-friendly output when writing to terminal
        if (cli.output_path == null) {
            _ = fout.?.write("\n") catch {};
        }
    } else {
        const opts = base64.DecodeOptions{ .variant = if (cli.url_safe) .url_safe else .standard, .ignore_whitespace = true };
        base64.decodeStream(fin.?, fout.?, opts) catch |e| {
            switch (e) {
                base64.DecodeError.InvalidCharacter => {
                    std.log.err("invalid input character", .{});
                    std.process.exit(1);
                },
                base64.DecodeError.InvalidPadding => {
                    std.log.err("invalid padding", .{});
                    std.process.exit(1);
                },
                base64.DecodeError.TruncatedInput => {
                    std.log.err("truncated or incomplete input", .{});
                    std.process.exit(1);
                },
                else => {
                    std.log.err("decode error: {s}", .{@errorName(e)});
                    std.process.exit(3);
                },
            }
        };
    }
}
