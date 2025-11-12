---
description: "Task breakdown for Base64 Encoder and Decoder implementation"
---

# Tasks: Base64 Encoder and Decoder

**Input**: Design documents from `/specs/001-base64-codec/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-contract.md

**Tests**: Tests are embedded in library via `test {}` blocks per Zig convention

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Single Zig project: `src/`, `build.zig` at repository root
- Tests embedded in source files via `test {}` blocks

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project structure per implementation plan
- [X] T002 Initialize Zig build system in build.zig
- [X] T003 [P] Create .gitignore for Zig artifacts and common patterns

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core library infrastructure that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Define Base64 encoding/decoding options structs (EncodeOptions, DecodeOptions) in src/base64.zig
- [X] T005 Define DecodeError error set (InvalidCharacter, InvalidPadding, TruncatedInput) in src/base64.zig
- [X] T006 [P] Implement alphabet tables (standard and URL-safe variants) in src/base64.zig
- [X] T007 [P] Implement reverse lookup table generation for decoding in src/base64.zig

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Encode Binary Data to Base64 (Priority: P1) 🎯 MVP

**Goal**: Convert arbitrary binary data to valid Base64 text representation

**Independent Test**: Encode "Hello" → verify output is "SGVsbG8="; encode empty → verify empty output; round-trip random binary data

### Implementation for User Story 1

- [X] T008 [P] [US1] Implement encodedLen calculation function in src/base64.zig
- [X] T009 [US1] Implement encodeInto (slice-based encoding) in src/base64.zig
- [X] T010 [US1] Implement encodeAlloc (allocating encoder) in src/base64.zig
- [X] T011 [US1] Implement encodeStream (streaming encoder for Reader/Writer) in src/base64.zig
- [X] T012 [P] [US1] Add RFC 4648 test vectors for encoding in src/base64.zig test blocks
- [X] T013 [P] [US1] Add empty input test for encoding in src/base64.zig test blocks
- [X] T014 [US1] Implement CLI encode mode with stdin/stdout support in src/main.zig
- [X] T015 [US1] Add CLI file input/output support for encode mode in src/main.zig

**Checkpoint**: User Story 1 complete - can encode binary to Base64 via library and CLI

---

## Phase 4: User Story 2 - Decode Base64 String to Binary Data (Priority: P1)

**Goal**: Convert Base64 text back to original binary data

**Independent Test**: Decode "SGVsbG8gV29ybGQ=" → verify "Hello World"; decode empty → verify empty; round-trip with US1

### Implementation for User Story 2

- [X] T016 [P] [US2] Implement decodedLenEstimate function in src/base64.zig
- [X] T017 [US2] Implement decodeInto (slice-based decoding) in src/base64.zig
- [X] T018 [US2] Implement decodeAlloc (allocating decoder) in src/base64.zig
- [X] T019 [US2] Implement decodeStream (streaming decoder for Reader/Writer) in src/base64.zig
- [X] T020 [P] [US2] Add RFC 4648 test vectors for decoding in src/base64.zig test blocks
- [X] T021 [P] [US2] Add whitespace handling test (spaces, tabs, newlines ignored) in src/base64.zig test blocks
- [X] T022 [US2] Implement CLI decode mode with stdin/stdout support in src/main.zig
- [X] T023 [US2] Add CLI file input/output support for decode mode in src/main.zig

**Checkpoint**: User Story 2 complete - can decode Base64 to binary via library and CLI

---

## Phase 5: User Story 3 - Handle Invalid Base64 Input Gracefully (Priority: P2)

**Goal**: Detect and report errors for malformed Base64 input

**Independent Test**: Decode invalid characters → verify InvalidCharacter error; decode truncated → verify TruncatedInput error; decode bad padding → verify InvalidPadding error

### Implementation for User Story 3

- [X] T024 [P] [US3] Add invalid character detection in decodeInto/decodeStream in src/base64.zig
- [X] T025 [P] [US3] Add padding validation in decodeInto/decodeStream in src/base64.zig
- [X] T026 [P] [US3] Add truncated input detection test in src/base64.zig test blocks
- [X] T027 [US3] Add human-readable error messages to stderr in CLI in src/main.zig
- [X] T028 [US3] Implement proper exit codes (1=invalid input, 2=I/O error, 3=internal) in src/main.zig

**Checkpoint**: User Story 3 complete - robust error handling for invalid input

---

## Phase 6: User Story 4 - Support Standard Base64 Variants (Priority: P3)

**Goal**: Support URL-safe alphabet and no-padding encoding modes

**Independent Test**: Encode with --url-safe → verify '-' and '_' instead of '+' and '/'; encode with --no-padding → verify no trailing '='

### Implementation for User Story 4

- [X] T029 [P] [US4] Add URL-safe variant support to encode/decode functions in src/base64.zig
- [X] T030 [P] [US4] Add no-padding option to encode functions in src/base64.zig
- [X] T031 [P] [US4] Add CLI flags --url-safe and --no-padding in src/main.zig
- [X] T032 [P] [US4] Add URL-safe and no-padding test cases in src/base64.zig test blocks

**Checkpoint**: User Story 4 complete - full variant support for specialized use cases

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation

- [X] T033 [P] Verify all source files use LF line endings (not CRLF)
- [X] T034 [P] Run quickstart.md validation scenarios
- [X] T035 Verify all RFC 4648 test vectors pass
- [ ] T036 Performance validation: encode/decode throughput >= 50 MB/s
- [ ] T037 Streaming validation: process multi-GB file without memory exhaustion
- [X] T038 Update README.md with build/usage instructions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately ✅ COMPLETE
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories ✅ COMPLETE
- **User Story 1 (Phase 3)**: Depends on Foundational completion ✅ COMPLETE
- **User Story 2 (Phase 4)**: Depends on Foundational completion ✅ COMPLETE
- **User Story 3 (Phase 5)**: Depends on US2 (needs decode to test errors) ✅ COMPLETE
- **User Story 4 (Phase 6)**: Depends on Foundational (extends encode/decode) ✅ COMPLETE
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Independent - only needs Foundational phase
- **User Story 2 (P1)**: Independent - only needs Foundational phase
- **User Story 3 (P2)**: Requires US2 for decoder error testing
- **User Story 4 (P3)**: Independent - extends Foundational encoding/decoding

### Within Each User Story

- Library functions before CLI integration
- Tests alongside or after implementation (Zig convention)
- Core encode/decode before streaming variants
- Basic functionality before variant support

### Parallel Opportunities

- **Phase 1**: All tasks marked [P] (T003)
- **Phase 2**: T006 and T007 can run in parallel
- **Phase 3**: T008, T012, T013 can run in parallel; T010 after T009
- **Phase 4**: T016, T020, T021 can run in parallel; T018 after T017
- **Phase 5**: T024, T025, T026 can run in parallel
- **Phase 6**: All tasks marked [P] can run in parallel
- **Phase 7**: T033, T034, T035, T036, T037 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch foundational tasks together:
Task T006: "Implement alphabet tables"
Task T007: "Implement reverse lookup table"

# Launch US1 parallel tasks together:
Task T008: "Implement encodedLen calculation"
Task T012: "Add RFC 4648 test vectors"
Task T013: "Add empty input test"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. ✅ Complete Phase 1: Setup
2. ✅ Complete Phase 2: Foundational
3. ✅ Complete Phase 3: User Story 1 (Encode)
4. ✅ Complete Phase 4: User Story 2 (Decode)
5. **Current**: Validate basic encode/decode functionality
6. **Next**: Add error handling (US3) and variants (US4)

### Incremental Delivery

1. ✅ Foundation → Library structure ready
2. ✅ US1 → Encoding works independently
3. ✅ US2 → Decoding works independently → **MVP COMPLETE**
4. ✅ US3 → Robust error handling
5. ✅ US4 → Full variant support
6. Polish → Production ready

### Current Status

**Phases Complete**: 1, 2, 3, 4, 5, 6 (Setup through User Story 4)
**Current Phase**: 7 (Polish & Validation)
**Remaining**: Final validation and documentation tasks

---

## Notes

- [P] tasks = different files or independent functions, can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story delivers independently testable value
- Zig tests embedded in source via `test {}` blocks
- Library-first: src/base64.zig before src/main.zig CLI
- LF line endings required for all generated files
- Exit codes: 0=success, 1=invalid input, 2=I/O error, 3=internal error
