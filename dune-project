(lang dune 3.16)
(name wordle)

(generate_opam_files true)

(authors "Hanliang Xu, Nancy Wu, Jiaqi Yu")
(maintainers "hxu110@jh.edu")
(source (github hanliang-xu/FPSE_Wordle))

(package
 (name wordle)
 (allow_empty)
 (synopsis "A functional Wordle implementation in OCaml with configurable word lengths and feedback modes")
 (description "A functional Wordle implementation in OCaml featuring configurable word lengths (2-10 letters), multiple feedback modes (ThreeState and Binary), API-based dictionary integration, frequency-based solver, and terminal UI with hints system. Demonstrates advanced OCaml features including functors, parametrized modules, and first-class modules.")
 (depends
  (ocaml (>= 4.14.0))
  (dune (>= 3.16))
  (core (>= v0.15.0))
  (core_unix (>= v0.15.0))
  (yojson (>= 2.0.0))
  (ppx_jane (>= v0.15.0))
  (ounit2 (and :with-test (>= 2.2.7)))
  (bisect_ppx (and :dev (>= 2.5.0)))
  (base_quickcheck :with-test))
 (license MIT))