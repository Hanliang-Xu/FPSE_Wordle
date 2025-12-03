run `dune clean` and `dune build src/bin/wordle.exe` to obtain the .exe file to run

run `dune clean && dune runtest --instrument-with bisect_ppx && bisect-ppx-report html && bisect-ppx-report summary` to generate the test coverage reports