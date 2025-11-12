# CLI Contract: zig-base64

## Command

`zig-base64`

## Subcommands / Modes

- `encode` (default if not specified)
- `decode`

## Flags

- `--decode` : Switch to decode mode (alternative to subcommand)
- `--url-safe` : Use URL-safe alphabet (`-` and `_`)
- `--no-padding` : Omit '=' padding on encode
- `--input <path>` : Read from file instead of stdin
- `--output <path>` : Write to file instead of stdout

## Input Rules

- If `--input` omitted: read all bytes from stdin (streaming)
- If `--decode` and whitespace present: ignore ASCII whitespace
- Reject invalid characters (non-alphabet / non-padding)
- Reject truncated input (final quantum incomplete without padding possibility)

## Output Rules

- Encode: produce Base64 string (with or without padding per flag) + newline
- Decode: write binary bytes exactly as recovered
- Errors: human-readable message to stderr; non-zero exit code

## Exit Codes

- `0` success
- `1` invalid input (bad character, bad padding, truncated)
- `2` I/O error (read/write failure)
- `3` internal/unexpected error

## Examples

```bash
# Encode file
zig-base64 encode --input data.bin --output data.b64

# Decode URL-safe without padding
zig-base64 decode --url-safe --input token.b64 --output token.bin

# Pipe encode
cat message.txt | zig-base64 > message.b64

# Pipe decode
cat message.b64 | zig-base64 --decode > message.txt
```
