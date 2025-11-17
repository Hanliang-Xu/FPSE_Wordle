#!/bin/bash
# Script to run feedback tests with coverage reporting

echo "Building and running feedback tests..."
dune clean
dune runtest src-test/feedback_test.exe

echo ""
echo "Generating coverage report..."
bisect-ppx-report html

echo ""
echo "Generating coverage summary..."
bisect-ppx-report summary

echo ""
echo "Coverage report generated! Open _coverage/index.html to view detailed report."
echo "Look for feedback.ml coverage in the report."

