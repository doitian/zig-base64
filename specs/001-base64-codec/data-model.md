# Data Model: Base64 Codec

## Entities

### BinaryData

- Description: Raw bytes to be encoded.
- Fields:
  - bytes: []const u8 (0..N)

### Base64String

- Description: Text encoding of BinaryData using defined alphabet and optional padding.
- Fields:
  - text: []const u8 (characters from A–Z, a–z, 0–9, +, /, -, _, '=')
  - variant: enum { standard, url_safe }
  - padded: bool

### CliOptions

- Description: CLI configuration for operations.
- Fields:
  - mode: enum { encode, decode }
  - url_safe: bool
  - no_padding: bool
  - input_path: ?[]const u8 (if null, read stdin)
  - output_path: ?[]const u8 (if null, write stdout)

## Constraints

- Decoder ignores ASCII whitespace in input.
- Decoder errors on invalid characters, bad padding, or truncated input.
- Encoder supports optional omission of '=' padding.
- Streaming APIs process arbitrarily large inputs without full buffering.
