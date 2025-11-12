# Quickstart: Base64 Encoder/Decoder

## Build

```bash
zig build
```

## Run CLI

```bash
# Encode from file
zig build run -- encode --input data.bin --output data.b64

# Decode from stdin
cat data.b64 | zig build run -- --decode > data.bin

# URL-safe encode without padding
zig build run -- encode --url-safe --no-padding --input token.bin --output token.b64
```

## Library Usage (Example)

```zig
const std = @import("std");
const base64 = @import("base64");

pub fn main() !void {
    const data: []const u8 = "foobar";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    const encoded = try base64.encodeAlloc(alloc, data, .{ .url_safe = false, .padding = true });
    defer alloc.free(encoded);
    std.debug.print("Encoded: {s}\n", .{encoded});
    const decoded = try base64.decodeAlloc(alloc, encoded, .{ .ignore_whitespace = true });
    defer alloc.free(decoded);
    std.debug.print("Decoded matches: {s}\n", .{decoded});
}
```
