# Wordle Game in OCaml

A functional Wordle implementation in OCaml with configurable word lengths, multiple feedback modes, and a terminal interface. Demonstrates advanced OCaml features including functors, parametrized modules, and first-class modules.

## Project Status

### What's Working ✅
- Core game logic with configurable word length (2-10 letters)
- ThreeState and Binary feedback modes with optional position distance hints
- API-based dictionary integration with local file fallback
- Frequency-based solver that competes against human players post-game
- Terminal UI with hints system (position-based and letter-based)
- **92.61% test coverage** across all modules

### What's Left to Do 🔨
- Upgrade solver from frequency-based to information theory-based (entropy maximization)
- Performance optimization and additional features (statistics, game history)

## Library Structure

The `src/lib/` directory contains a well-structured library using functors extensively:

- **`Wordle_functor.Make`**: Main functor composing all game modules (`Guess.Make`, `Game.Make`, `Solver.Make`, `Utils.Make`)
- **`Config`**: Module type for game configuration (word length, feedback granularity, position distances)
- **Core modules**: `Dict`, `Feedback`, `Hints`, `UI`, `Game_loop`

All modules are parametrized to work with any word length and feedback mode, demonstrating abstraction and reusability.

## Building and Running

```bash
# Build
dune build

# Run game
dune exec src/bin/wordle.exe

# Run tests
dune test

# Generate coverage report
dune clean && dune runtest --instrument-with bisect_ppx && bisect-ppx-report html && bisect-ppx-report summary
```

## Test Coverage

**92.61% coverage (451/487 lines)** with comprehensive test suites covering:
- All core modules (Config, Dict, Feedback, Game, Guess, Solver, Utils, Hints, UI)
- Integration tests for functor composition and end-to-end game flow
- Mocking for stdin/stdout interactions and API error handling

## Grading Rubric Alignment

**30% Progress**: ~80% complete. Core mechanics, UI, solver, hints, and testing functional. Remaining work: solver enhancement.

**3% Evidence of Library**: `src/lib/` contains functors (`Wordle_functor.Make`, `Guess.Make`, `Game.Make`, `Solver.Make`, `Utils.Make`), module types (`Config.Config`), and clear separation from executables/tests.

**3% Algorithmic Complexity**: Frequency-based solver with distance hints, duplicate letter handling, position distance calculation, API integration with JSON parsing, complex functor-based module system.

**24% Module Design**: Extensive functor use (`Make` pattern), well-defined `.mli` interfaces, clear separation of concerns, `Wordle_functor` composition, consistent patterns.

**25% Code Quality**: Strong typing, functional style with immutable data structures, proper error handling (`result` types), comprehensive documentation, logical organization, OCaml idioms.

**15% Tests**: 92.61% coverage, comprehensive module coverage, integration tests, mocking for I/O and APIs, well-organized test suites, all tests buildable with `dune test`.

## Repository Structure

```
FPSE_Wordle/
├── src/lib/          # Library code (functors, modules)
├── src/bin/          # Executables
├── src-test/         # Test suites
└── data/             # Answer word lists
```

## Dependencies

Core, Core_unix, OUnit2, Yojson, Bisect_ppx
