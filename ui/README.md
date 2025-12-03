# Wordle Web UI

This is the main web application for the Wordle game, built with OCaml's Dream web framework.

## Structure

```
ui/
├── wordle_web.ml    # Main OCaml Dream web server
├── dune             # Build configuration
├── README.md        # This file
└── static/
    ├── app.js       # Frontend JavaScript
    └── styles.css   # Frontend CSS
```

## Features

- Full Wordle gameplay with 5-letter words
- AI Solver integration
- Beautiful modern UI
- Session-based game state
- Statistics tracking (in browser localStorage)
- Help and stats modals

## How to Run

### Build and run from project root:

```bash
# Build the web application
dune build ui/wordle_web.exe

# Run the server
./_build/default/ui/wordle_web.exe
```

### Alternative with opam exec:

```bash
opam exec -- dune build ui/wordle_web.exe
opam exec -- ./_build/default/ui/wordle_web.exe
```

### Or use dune exec:

```bash
dune exec ui/wordle_web.exe
```

## Access

Once running, open your browser to:

```
http://localhost:8080
```

## API Endpoints

- `GET /` - Main game page
- `POST /api/new-game` - Start new game
- `POST /api/guess` - Submit a guess
- `GET /api/solver/suggest` - Get AI suggestion
- `GET /api/state` - Get current game state
- `GET /static/**` - Static assets (JS, CSS)

## Integration

This web app integrates with your OCaml backend:
- `Dict` module - Word dictionaries and validation
- `Wordle_functor` - Creates game instance
- `Game` module - Game state management
- `Solver` module - AI solver functionality
- `Feedback` module - Letter feedback (Green/Yellow/Grey)

## Notes

- Currently configured for 5-letter words
- Session resets when server restarts
- Statistics stored in browser localStorage
- Static files served from `ui/static/`

