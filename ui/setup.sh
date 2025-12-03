#!/bin/bash

# Setup script for Wordle Web App Dependencies
echo "🔧 Setting up Wordle Web App dependencies..."

# Install required opam packages
echo "📦 Installing OCaml packages (core, core_unix, ppx_jane, dream)..."
opam install core core_unix ppx_jane dream --yes

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
    echo ""
    echo "👉 Now run: ./ui/run.sh"
else
    echo "❌ Failed to install dependencies."
    echo "Please check your opam installation and network connection."
fi

