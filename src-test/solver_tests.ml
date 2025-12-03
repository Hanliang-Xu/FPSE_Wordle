(** Comprehensive test suite for Solver module *)

open Core
open OUnit2

(** Create Guess module for testing *)
module Config5 = struct
  let word_length = 5
  let feedback_granularity = Lib.Config.ThreeState
end

module Guess5 = Lib.Guess.Make (Config5)
module Solver5 = Lib.Solver.Make (Guess5)

(** Test create *)
let test_create_with_words _ =
  let word_list = ["hello"; "world"; "test"] in
  let solver = Solver5.create word_list in
  let guess = Solver5.make_guess solver in
  assert_bool "Should return first word from list" 
    (String.equal guess "hello")

let test_create_with_single_word _ =
  let word_list = ["crane"] in
  let solver = Solver5.create word_list in
  let guess = Solver5.make_guess solver in
  assert_equal "crane" guess ~printer:Fn.id

let test_create_with_empty_list _ =
  let solver = Solver5.create [] in
  let guess = Solver5.make_guess solver in
  (* Should use fallback default word *)
  assert_equal "CRANE" guess ~printer:Fn.id

let test_create_with_large_list _ =
  let word_list = List.init 100 ~f:(fun i -> Printf.sprintf "word%03d" i) in
  let solver = Solver5.create word_list in
  let guess = Solver5.make_guess solver in
  assert_equal "word000" guess ~printer:Fn.id

(** Test make_guess *)
let test_make_guess_consistency _ =
  let word_list = ["hello"] in
  let solver = Solver5.create word_list in
  (* Make multiple guesses - should be consistent *)
  let guess1 = Solver5.make_guess solver in
  let guess2 = Solver5.make_guess solver in
  let guess3 = Solver5.make_guess solver in
  assert_equal guess1 guess2 ~printer:Fn.id;
  assert_equal guess2 guess3 ~printer:Fn.id;
  assert_equal "hello" guess1 ~printer:Fn.id

(** Test update *)
let test_update_does_not_change_guess _ =
  let word_list = ["hello"] in
  let solver = Solver5.create word_list in
  let initial_guess = Solver5.make_guess solver in
  
  (* Create feedback *)
  let feedback = Guess5.make_feedback "hello" "world" in
  let updated_solver = Solver5.update solver feedback in
  
  (* Guess should remain the same (dummy solver ignores feedback) *)
  let new_guess = Solver5.make_guess updated_solver in
  assert_equal initial_guess new_guess ~printer:Fn.id

let test_update_with_correct_feedback _ =
  let word_list = ["hello"] in
  let solver = Solver5.create word_list in
  let feedback = Guess5.make_feedback "hello" "hello" in
  let updated_solver = Solver5.update solver feedback in
  (* Dummy solver ignores feedback, so guess should be same *)
  let guess = Solver5.make_guess updated_solver in
  assert_equal "hello" guess ~printer:Fn.id

let test_update_with_partial_feedback _ =
  let word_list = ["crane"] in
  let solver = Solver5.create word_list in
  let feedback = Guess5.make_feedback "crane" "trace" in
  let updated_solver = Solver5.update solver feedback in
  let guess = Solver5.make_guess updated_solver in
  assert_equal "crane" guess ~printer:Fn.id

let test_update_multiple_times _ =
  let word_list = ["test"] in
  let solver = Solver5.create word_list in
  let feedback1 = Guess5.make_feedback "test" "word" in
  let solver1 = Solver5.update solver feedback1 in
  let feedback2 = Guess5.make_feedback "test" "code" in
  let solver2 = Solver5.update solver1 feedback2 in
  let feedback3 = Guess5.make_feedback "test" "play" in
  let solver3 = Solver5.update solver2 feedback3 in
  (* All should return same guess *)
  let guess = Solver5.make_guess solver3 in
  assert_equal "test" guess ~printer:Fn.id

(** Test with different word lengths *)
module Config3 = struct
  let word_length = 3
  let feedback_granularity = Lib.Config.ThreeState
end

module Guess3 = Lib.Guess.Make (Config3)
module Solver3 = Lib.Solver.Make (Guess3)

let test_solver_3letter _ =
  let word_list = ["cat"; "dog"] in
  let solver = Solver3.create word_list in
  let guess = Solver3.make_guess solver in
  assert_equal "cat" guess ~printer:Fn.id

(** Test with binary mode *)
module Config5Binary = struct
  let word_length = 5
  let feedback_granularity = Lib.Config.Binary
end

module Guess5Binary = Lib.Guess.Make (Config5Binary)
module Solver5Binary = Lib.Solver.Make (Guess5Binary)

let test_solver_binary_mode _ =
  let word_list = ["hello"; "world"] in
  let solver = Solver5Binary.create word_list in
  let feedback = Guess5Binary.make_feedback "hello" "world" in
  let updated_solver = Solver5Binary.update solver feedback in
  let guess = Solver5Binary.make_guess updated_solver in
  assert_equal "hello" guess ~printer:Fn.id

let suite =
  "Solver module tests" >::: [
    "create_with_words" >:: test_create_with_words;
    "create_with_single_word" >:: test_create_with_single_word;
    "create_with_empty_list" >:: test_create_with_empty_list;
    "create_with_large_list" >:: test_create_with_large_list;
    "make_guess_consistency" >:: test_make_guess_consistency;
    "update_does_not_change_guess" >:: test_update_does_not_change_guess;
    "update_with_correct_feedback" >:: test_update_with_correct_feedback;
    "update_with_partial_feedback" >:: test_update_with_partial_feedback;
    "update_multiple_times" >:: test_update_multiple_times;
    "solver_3letter" >:: test_solver_3letter;
    "solver_binary_mode" >:: test_solver_binary_mode;
  ]

let () = run_test_tt_main suite

