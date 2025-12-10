#!/bin/bash

# Build and run the Wordle Web Application
echo "🎮 Building Wordle Web Application..."
cd "$(dirname "$0")/.." || exit

# Check if static files exist, if not copy them
if [ ! -f "ui/static/styles.css" ] || [ ! -f "ui/static/app.js" ]; then
    echo "📦 Setting up frontend files..."
    mkdir -p ui/static
    
    if [ -f "demo/dream/static/styles.css" ]; then
        cp demo/dream/static/styles.css ui/static/
        echo "   ✓ Copied styles.css"
    fi
    
    if [ -f "demo/dream/static/app.js" ]; then
        cp demo/dream/static/app.js ui/static/
        echo "   ✓ Copied app.js"
    fi
    echo ""
fi

# Build the application
opam exec -- dune build ui/wordle_web.exe

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "🚀 Starting server on http://localhost:8081"
    echo "   Press Ctrl+C to stop the server"
    echo ""
    ./_build/default/ui/wordle_web.exe
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi

