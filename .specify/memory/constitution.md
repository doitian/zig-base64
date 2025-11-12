<!--
Sync Impact Report - Constitution Update
=========================================
Version Change: Initial → 1.0.0
Created: 2025-11-12

Modified Principles: N/A (initial version)
Added Sections: All core principles established
Removed Sections: None

Templates Status:
✅ plan-template.md - Aligned (Constitution Check section ready)
✅ spec-template.md - Aligned (Test-first requirements compatible)
✅ tasks-template.md - Aligned (Test-first workflow supported)
✅ Command files - No agent-specific references to update

Follow-up TODOs: None
-->

# Zig Base64 Library Constitution

## Core Principles

### I. Library-First Architecture

All functionality MUST be implemented as reusable library modules before any
CLI or application-level code. Each module MUST be:

- Self-contained with clear boundaries and minimal dependencies
- Independently testable without requiring external services or state
- Documented with public API contracts and usage examples
- Purposeful - no organizational-only modules without concrete functionality

**Rationale**: Library-first design enforces modularity, enables reusability
across projects, and ensures each component can be tested and maintained in
isolation. This is critical for a codec library that may be embedded in
various contexts.

### II. CLI as Library Consumer

Every library module MUST expose its functionality through a command-line
interface. CLI tools MUST follow these protocols:

- Input via stdin or command-line arguments
- Output successful results to stdout
- Output errors and diagnostics to stderr
- Support both machine-readable (JSON) and human-readable formats
- Return appropriate exit codes (0 for success, non-zero for errors)

**Rationale**: CLIs provide testable, scriptable interfaces for validation
and debugging. They demonstrate correct library usage and enable automation.
Text-based protocols ensure transparency and ease of troubleshooting.

### III. Test-First Development (NON-NEGOTIABLE)

Test-Driven Development is mandatory. Implementation workflow MUST follow:

1. Write test cases based on specifications
2. Obtain approval/validation of test coverage
3. Run tests and verify they FAIL (red phase)
4. Implement minimal code to pass tests (green phase)
5. Refactor while maintaining passing tests

Tests MUST be written BEFORE implementation code. No exceptions.

**Rationale**: Test-first development catches design issues early, ensures
specifications are correctly understood, provides living documentation, and
prevents regression. For codec libraries, correctness is critical - test
vectors from RFC 4648 MUST pass with 100% accuracy.

### IV. Contract and Integration Testing

The following scenarios require explicit contract or integration tests:

- New library modules exposing public APIs
- Changes to existing library contracts or function signatures
- Inter-module communication and data exchange
- Shared data structures or protocols
- RFC compliance verification (e.g., RFC 4648 test vectors)

Contract tests MUST verify interface compatibility. Integration tests MUST
verify end-to-end workflows across module boundaries.

**Rationale**: Unit tests alone cannot catch integration failures. Codec
libraries require verification against standardized test vectors and
round-trip encoding/decoding validation.

### V. Performance and Correctness

Performance is a first-class requirement for codec libraries. All
implementations MUST:

- Meet or exceed specified throughput targets (e.g., 50 MB/s for base64)
- Include performance benchmarks as part of the test suite
- Optimize for both speed and memory efficiency
- Document algorithmic complexity for all public operations
- Prioritize correctness over performance when trade-offs are required

**Rationale**: Codec libraries are often performance-critical. Users expect
competitive throughput. However, correctness cannot be sacrificed - a fast
but incorrect encoder is worthless.

### VI. Simplicity and YAGNI

Start with the simplest solution that meets requirements. Complexity MUST be
justified:

- Implement only specified features (You Aren't Gonna Need It)
- Prefer clear, readable code over clever optimizations unless benchmarks
  prove necessity
- Avoid premature abstraction - wait until patterns emerge from 3+ use cases
- Document and justify any complexity in the implementation plan

**Rationale**: Simplicity reduces bugs, eases maintenance, and speeds
development. Zig's philosophy emphasizes explicit, straightforward code. Add
complexity only when demonstrated needs justify it.

## Technical Standards

### Language and Tooling

- **Language**: Zig (version to be specified in plan.md for each feature)
- **Build System**: Zig build system
- **Testing**: Zig test framework
- **Documentation**: Inline doc comments + generated docs
- **Formatting**: `zig fmt` (enforced in CI)

### Code Quality Gates

All code MUST pass:

- `zig fmt` formatting checks (no manual formatting)
- `zig build test` with 100% pass rate
- Contract tests for all public APIs
- RFC compliance tests where applicable
- Performance benchmarks meeting specified targets

### Error Handling

- Use Zig error unions for fallible operations
- Provide descriptive error messages for all failure modes
- Document all possible error returns in public API contracts
- Never silently ignore errors

## Development Workflow

### Feature Development Cycle

1. **Specification** (`/speckit.specify`): Technology-agnostic requirements
2. **Planning** (`/speckit.plan`): Technical design and architecture
3. **Task Breakdown** (`/speckit.tasks`): Granular implementation tasks
4. **Test-First Implementation**: Write tests → verify failure → implement
5. **Validation**: Run full test suite + benchmarks
6. **Documentation**: Update API docs and examples

### Constitution Compliance

Every implementation plan MUST include a "Constitution Check" section
verifying adherence to all principles. Any violations MUST be:

- Explicitly identified and documented
- Justified with specific technical reasoning
- Accompanied by explanation of why simpler alternatives are insufficient

### Quality Assurance

- All user stories MUST have acceptance tests before implementation
- RFC compliance MUST be verified with standardized test vectors
- Performance benchmarks MUST be run and results documented
- Code reviews MUST verify constitution compliance

## Governance

This constitution is the authoritative source for development standards and
practices. It supersedes all conflicting guidance.

### Amendment Process

Constitution changes require:

1. Documented proposal with rationale
2. Impact analysis on existing features and templates
3. Version bump following semantic versioning
4. Update of all dependent templates and documentation
5. Sync Impact Report documenting all changes

### Versioning Policy

- **MAJOR**: Backward-incompatible principle removals or redefinitions
- **MINOR**: New principles added or material guidance expansions
- **PATCH**: Clarifications, wording improvements, non-semantic fixes

### Compliance

- All pull requests MUST verify constitution compliance
- Implementation plans MUST justify any complexity or deviations
- Test failures MUST block merges
- Performance regressions MUST be justified or rejected

**Version**: 1.0.0 | **Ratified**: 2025-11-12 | **Last Amended**: 2025-11-12
