# Base64 Encoder/Decoder

A standards-compliant Base64 encoder and decoder implementation in Zig, following RFC 4648.

## Features

- ✅ **RFC 4648 Compliant**: Passes all standard test vectors
- ✅ **Multiple Variants**: Standard and URL-safe Base64 alphabets
- ✅ **Flexible Padding**: Support for with/without padding
- ✅ **Streaming Support**: Process arbitrarily large files with constant memory usage
- ✅ **Robust Error Handling**: Clear error messages for invalid input
- ✅ **Library + CLI**: Use as a library or command-line tool

## Build

```bash
zig build
```

## CLI Usage

### Encode

```bash
# From stdin to stdout
echo "Hello, World!" | ./zig-out/bin/zig-base64 encode

# From file to file
./zig-out/bin/zig-base64 encode --input data.bin --output data.b64

# URL-safe encoding without padding
./zig-out/bin/zig-base64 encode --url-safe --no-padding --input token.bin --output token.b64
```

### Decode

```bash
# From stdin to stdout
cat data.b64 | ./zig-out/bin/zig-base64 decode

# From file to file
./zig-out/bin/zig-base64 decode --input data.b64 --output data.bin

# URL-safe decoding
./zig-out/bin/zig-base64 decode --url-safe --input token.b64
```

### CLI Options

- `encode` or `decode` - Operation mode (default: encode)
- `--url-safe` - Use URL-safe alphabet (`-` and `_` instead of `+` and `/`)
- `--no-padding` - Omit padding `=` characters on encode
- `--input <path>` - Read from file instead of stdin
- `--output <path>` - Write to file instead of stdout

### Exit Codes

- `0` - Success
- `1` - Invalid input (bad characters, padding, or truncated data)
- `2` - I/O error
- `3` - Internal error

## Library Usage

```zig
const std = @import("std");
const base64 = @import("base64.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // Encode
    const data: []const u8 = "Hello, World!";
    const encoded = try base64.encodeAlloc(alloc, data, .{});
    defer alloc.free(encoded);
    std.debug.print("Encoded: {s}\n", .{encoded});

    // Decode
    const decoded = try base64.decodeAlloc(alloc, encoded, .{});
    defer alloc.free(decoded);
    std.debug.print("Decoded: {s}\n", .{decoded});
}
```

### API Overview

#### Encoding

```zig
// Calculate output size
pub fn encodedLen(input_len: usize, padding: bool) usize

// Allocate and encode
pub fn encodeAlloc(alloc: Allocator, input: []const u8, opts: EncodeOptions) ![]u8

// Encode into pre-allocated buffer
pub fn encodeInto(out: []u8, input: []const u8, opts: EncodeOptions) !usize

// Stream encoding (File to File)
pub fn encodeStream(reader: std.fs.File, writer: std.fs.File, opts: EncodeOptions) !void
```

#### Decoding

```zig
// Estimate output size
pub fn decodedLenEstimate(input: []const u8, opts: DecodeOptions) !usize

// Allocate and decode
pub fn decodeAlloc(alloc: Allocator, input: []const u8, opts: DecodeOptions) ![]u8

// Decode into pre-allocated buffer
pub fn decodeInto(out: []u8, input: []const u8, opts: DecodeOptions) !usize

// Stream decoding (File to File)
pub fn decodeStream(reader: std.fs.File, writer: std.fs.File, opts: DecodeOptions) !void
```

#### Options

```zig
pub const EncodeOptions = struct {
    variant: Variant = .standard,  // .standard or .url_safe
    padding: bool = true,           // Include padding '=' characters
};

pub const DecodeOptions = struct {
    variant: Variant = .standard,       // .standard or .url_safe
    ignore_whitespace: bool = true,     // Ignore spaces, tabs, newlines
};
```

#### Errors

```zig
pub const DecodeError = error{
    InvalidCharacter,   // Non-Base64 character found
    InvalidPadding,     // Incorrect padding format
    TruncatedInput,     // Incomplete Base64 input
};
```

## Testing

Run the test suite:

```bash
zig build test
```

Or test the library directly:

```bash
zig test src/base64.zig
```

Tests include:

- RFC 4648 test vectors
- Whitespace handling
- Truncated input detection
- Round-trip encoding/decoding

## Performance

The implementation uses table-based encoding/decoding for optimal performance:

- **Target**: ≥ 50 MB/s throughput for both encode and decode
- **Streaming**: Constant memory usage regardless of file size
- **Chunking**: Efficient buffer management for large files

## Specification

Full feature specification and implementation plan available in `specs/001-base64-codec/`:

- `spec.md` - Feature requirements and acceptance criteria
- `plan.md` - Implementation strategy and architecture
- `tasks.md` - Detailed task breakdown
- `contracts/cli-contract.md` - CLI behavior specification

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]
