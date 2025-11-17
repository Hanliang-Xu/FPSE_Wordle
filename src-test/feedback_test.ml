(** Comprehensive test suite for Feedback module *)

open Core
open OUnit2

(* Create a test configuration for 5-letter words *)
module Config5 = struct
  let word_length = 5
end

module Feedback5 = Feedback.Make (Config5)

(* Helper function to convert color list to string for easier comparison *)
let color_list_to_string colors =
  List.map colors ~f:(function
    | Feedback5.Green -> "G"
    | Feedback5.Yellow -> "Y"
    | Feedback5.Grey -> ".")
  |> String.concat ~sep:""

(* Test generate function - exact match *)
let test_generate_all_correct _ =
  let colors = Feedback5.generate "HELLO" "HELLO" in
  assert_equal "GGGGG" (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - all wrong *)
let test_generate_all_wrong _ =
  let colors = Feedback5.generate "ABCDE" "FGHIJ" in
  assert_equal "....." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - partial matches *)
let test_generate_partial_matches _ =
  let colors = Feedback5.generate "HELLO" "WORLD" in
  (* H-W(.), E-O(.), L-R(.), L-L(G), O-D(.) *)
  assert_equal "...G." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - yellow letters *)
let test_generate_yellow_letters _ =
  let colors = Feedback5.generate "WORLD" "BELOW" in
  (* W-B(.), O-E(.), R-L(.), L-O(Y), D-W(.) *)
  assert_equal "..YY." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - duplicate letters in guess, single in answer *)
let test_generate_duplicate_guess_single_answer _ =
  let colors = Feedback5.generate "SPEED" "ABIDE" in
  (* S-A(.), P-B(.), E-I(.), E-D(Y), D-E(.) *)
  assert_equal "...Y." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - duplicate letters, one correct position *)
let test_generate_duplicate_one_green _ =
  let colors = Feedback5.generate "FLOOR" "ROBOT" in
  (* F-R(.), L-O(.), O-B(Y), O-O(G), R-T(.) *)
  assert_equal "..YG." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - duplicate letters, both wrong position *)
let test_generate_duplicate_both_yellow _ =
  let colors = Feedback5.generate "REELS" "LEVER" in
  (* R-L(.), E-E(G), E-V(Y), L-E(.), S-R(.) *)
  assert_equal ".GY.." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - triple duplicate letters *)
let test_generate_triple_duplicates _ =
  let colors = Feedback5.generate "EEEEE" "REBEL" in
  (* E-R(.), E-E(G), E-B(.), E-E(G), E-L(.) *)
  assert_equal ".G.G." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - complex duplicate scenario *)
let test_generate_complex_duplicates _ =
  let colors = Feedback5.generate "LLAMA" "LABEL" in
  (* L-L(G), L-A(Y), A-B(.), M-E(.), A-L(.) *)
  assert_equal "GY..." (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - all same letter *)
let test_generate_all_same_letter _ =
  let colors = Feedback5.generate "AAAAA" "AAAAA" in
  assert_equal "GGGGG" (color_list_to_string colors) ~printer:Fn.id

(* Test generate function - mix of green, yellow, grey *)
let test_generate_mixed_feedback _ =
  let colors = Feedback5.generate "CRANE" "TRACE" in
  (* C-T(.), R-R(G), A-A(G), N-C(.), E-E(G) *)
  assert_equal ".GG.G" (color_list_to_string colors) ~printer:Fn.id

(* Test make_feedback function *)
let test_make_feedback _ =
  let feedback = Feedback5.make_feedback "HELLO" "WORLD" in
  assert_equal "HELLO" feedback.guess ~printer:Fn.id;
  assert_equal "...G." (color_list_to_string feedback.colors) ~printer:Fn.id

(* Test is_correct - all green *)
let test_is_correct_true _ =
  let feedback = Feedback5.make_feedback "HELLO" "HELLO" in
  assert_bool "Should be correct" (Feedback5.is_correct feedback)

(* Test is_correct - has yellow *)
let test_is_correct_with_yellow _ =
  let feedback = Feedback5.make_feedback "WORLD" "BELOW" in
  assert_bool "Should not be correct" (not (Feedback5.is_correct feedback))

(* Test is_correct - has grey *)
let test_is_correct_with_grey _ =
  let feedback = Feedback5.make_feedback "ABCDE" "FGHIJ" in
  assert_bool "Should not be correct" (not (Feedback5.is_correct feedback))

(* Test is_correct - partial match *)
let test_is_correct_partial _ =
  let feedback = Feedback5.make_feedback "CRANE" "TRACE" in
  assert_bool "Should not be correct" (not (Feedback5.is_correct feedback))

(* Test color_to_string - Green *)
let test_color_to_string_green _ =
  assert_equal "G" (Feedback5.color_to_string Feedback5.Green) ~printer:Fn.id

(* Test color_to_string - Yellow *)
let test_color_to_string_yellow _ =
  assert_equal "Y" (Feedback5.color_to_string Feedback5.Yellow) ~printer:Fn.id

(* Test color_to_string - Grey *)
let test_color_to_string_grey _ =
  assert_equal "." (Feedback5.color_to_string Feedback5.Grey) ~printer:Fn.id

(* Test colors_to_string - mixed *)
let test_colors_to_string_mixed _ =
  let colors = [Feedback5.Green; Feedback5.Yellow; Feedback5.Grey; Feedback5.Green; Feedback5.Yellow] in
  assert_equal "GY.GY" (Feedback5.colors_to_string colors) ~printer:Fn.id

(* Test colors_to_string - all green *)
let test_colors_to_string_all_green _ =
  let colors = [Feedback5.Green; Feedback5.Green; Feedback5.Green; Feedback5.Green; Feedback5.Green] in
  assert_equal "GGGGG" (Feedback5.colors_to_string colors) ~printer:Fn.id

(* Test colors_to_string - empty *)
let test_colors_to_string_empty _ =
  let colors = [] in
  assert_equal "" (Feedback5.colors_to_string colors) ~printer:Fn.id

(* Test to_string *)
let test_to_string _ =
  let feedback = Feedback5.make_feedback "HELLO" "WORLD" in
  assert_equal "HELLO: ...G." (Feedback5.to_string feedback) ~printer:Fn.id

(* Test to_string - all correct *)
let test_to_string_all_correct _ =
  let feedback = Feedback5.make_feedback "WORLD" "WORLD" in
  assert_equal "WORLD: GGGGG" (Feedback5.to_string feedback) ~printer:Fn.id

(* Test to_string - all wrong *)
let test_to_string_all_wrong _ =
  let feedback = Feedback5.make_feedback "ABCDE" "FGHIJ" in
  assert_equal "ABCDE: ....." (Feedback5.to_string feedback) ~printer:Fn.id

(* Test with different word length configuration *)
module Config3 = struct
  let word_length = 3
end

module Feedback3 = Feedback.Make (Config3)

let test_generate_3letter _ =
  let colors = Feedback3.generate "CAT" "BAT" in
  (* C-B(.), A-A(G), T-T(G) *)
  let result = List.map colors ~f:(function
    | Feedback3.Green -> "G"
    | Feedback3.Yellow -> "Y"
    | Feedback3.Grey -> ".")
  |> String.concat ~sep:""
  in
  assert_equal ".GG" result ~printer:Fn.id

let test_generate_3letter_all_correct _ =
  let colors = Feedback3.generate "DOG" "DOG" in
  let result = List.map colors ~f:(function
    | Feedback3.Green -> "G"
    | Feedback3.Yellow -> "Y"
    | Feedback3.Grey -> ".")
  |> String.concat ~sep:""
  in
  assert_equal "GGG" result ~printer:Fn.id

(* Edge case: repeated letters where answer has more occurrences than guess *)
let test_generate_answer_has_more_duplicates _ =
  let colors = Feedback5.generate "BELLE" "LABEL" in
  (* B-L(.), E-A(.), L-B(.), L-E(Y), E-L(Y) *)
  assert_equal "...YY" (color_list_to_string colors) ~printer:Fn.id

(* Edge case: all letters in wrong positions *)
let test_generate_all_wrong_positions _ =
  let colors = Feedback5.generate "ABCDE" "BCDEA" in
  (* A-B(Y), B-C(Y), C-D(Y), D-E(Y), E-A(Y) *)
  assert_equal "YYYYY" (color_list_to_string colors) ~printer:Fn.id

(* Build the test suite *)
let test_suite =
  "Feedback Tests" >::: [
    "test_generate_all_correct" >:: test_generate_all_correct;
    "test_generate_all_wrong" >:: test_generate_all_wrong;
    "test_generate_partial_matches" >:: test_generate_partial_matches;
    "test_generate_yellow_letters" >:: test_generate_yellow_letters;
    "test_generate_duplicate_guess_single_answer" >:: test_generate_duplicate_guess_single_answer;
    "test_generate_duplicate_one_green" >:: test_generate_duplicate_one_green;
    "test_generate_duplicate_both_yellow" >:: test_generate_duplicate_both_yellow;
    "test_generate_triple_duplicates" >:: test_generate_triple_duplicates;
    "test_generate_complex_duplicates" >:: test_generate_complex_duplicates;
    "test_generate_all_same_letter" >:: test_generate_all_same_letter;
    "test_generate_mixed_feedback" >:: test_generate_mixed_feedback;
    "test_make_feedback" >:: test_make_feedback;
    "test_is_correct_true" >:: test_is_correct_true;
    "test_is_correct_with_yellow" >:: test_is_correct_with_yellow;
    "test_is_correct_with_grey" >:: test_is_correct_with_grey;
    "test_is_correct_partial" >:: test_is_correct_partial;
    "test_color_to_string_green" >:: test_color_to_string_green;
    "test_color_to_string_yellow" >:: test_color_to_string_yellow;
    "test_color_to_string_grey" >:: test_color_to_string_grey;
    "test_colors_to_string_mixed" >:: test_colors_to_string_mixed;
    "test_colors_to_string_all_green" >:: test_colors_to_string_all_green;
    "test_colors_to_string_empty" >:: test_colors_to_string_empty;
    "test_to_string" >:: test_to_string;
    "test_to_string_all_correct" >:: test_to_string_all_correct;
    "test_to_string_all_wrong" >:: test_to_string_all_wrong;
    "test_generate_3letter" >:: test_generate_3letter;
    "test_generate_3letter_all_correct" >:: test_generate_3letter_all_correct;
    "test_generate_answer_has_more_duplicates" >:: test_generate_answer_has_more_duplicates;
    "test_generate_all_wrong_positions" >:: test_generate_all_wrong_positions;
  ]

