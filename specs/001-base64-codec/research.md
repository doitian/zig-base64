# Research: Base64 Encoder and Decoder

## Decisions

- Decision: Use Zig standard library only (no external deps)
  - Rationale: Keep the library portable, minimal, and aligned with constitution simplicity. Zig std provides I/O primitives; we implement Base64 logic per spec.
  - Alternatives: Use std.base64 helpers — rejected to meet exercise goals and control behavior (whitespace, streaming, URL-safe, no-padding) explicitly.

- Decision: Streaming support for arbitrarily large files (Reader/Writer API)
  - Rationale: Meets clarified requirement; enables constant-memory processing.
  - Alternatives: In-memory only — rejected; conflicts with clarification.

- Decision: CLI supports both stdin/stdout and file paths
  - Rationale: Aligns with constitution; allows piping and file workflows.
  - Alternatives: Files only or stdin only — rejected; reduces usability.

- Decision: Human-readable errors to stderr
  - Rationale: Easier for end users; JSON can be added later if needed.

- Decision: Ignore whitespace during decoding
  - Rationale: Usability and compatibility with formatted Base64; still validates other characters strictly.

- Decision: Padding handling
  - Rationale: Encoder supports optional no-padding; decoder accepts missing padding and infers.

- Decision: Zig version
  - Rationale: Target Zig 0.12+ (stable APIs for std.io Reader/Writer). Exact version can be adjusted.

## Alphabet and Padding (Per User Instruction)

- 0..25 → 'A'..'Z'
- 26..51 → 'a'..'z'
- 52..61 → '0'..'9'
- 62 → '+'
- 63 → '/'
- '=' padding indicates end of meaningful output

URL-safe variant switches '+'→'-' and '/'→'_'.

## Test Vectors (RFC 4648)

- "" → ""
- "f" → "Zg=="
- "fo" → "Zm8="
- "foo" → "Zm9v"
- "foob" → "Zm9vYg=="
- "fooba" → "Zm9vYmE="
- "foobar" → "Zm9vYmFy"

## Performance Notes

- Implement table-based encode (24-bit grouping) and decode (reverse table).
- Chunk sizes: encode read 3kB multiples; decode read 4kB multiples; maintain carry-over across chunks.
- Avoid heap in streaming paths; use stack buffers; slice APIs allocate once via provided allocator.

## Risks

- Incorrect padding edge cases — addressed by dedicated tests.
- Whitespace handling — ensure decoder strips only ASCII whitespace and rejects other invalid chars.
- Windows vs LF line endings — enforce LF on all generated files.
