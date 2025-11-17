#!/bin/bash
# Script to run guess tests with coverage reporting

echo "Building and running guess module tests..."
dune clean
dune runtest src-test/guess_test.exe

echo ""
echo "Generating coverage report..."
bisect-ppx-report html

echo ""
echo "Generating coverage summary..."
bisect-ppx-report summary

echo ""
echo "Coverage report generated! Open _coverage/index.html to view detailed report."
echo "Look for guess.ml coverage in the report."

