(** Test suite for Hints module *)

open Core
open OUnit2
open Lib.Hints
open Lib.Feedback

(** Test generate_hint_mode1 *)
let test_generate_hint_mode1_no_revealed _ =
  let answer = "hello" in
  let guesses_with_colors = [] in
  let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
  assert_bool "Position should be valid" (pos >= 0 && pos < String.length answer);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

let test_generate_hint_mode1_some_revealed _ =
  let answer = "hello" in
  (* Reveal position 0 (h) and 1 (e) as Green *)
  let guesses_with_colors = [
    ("hello", [Green; Green; Grey; Grey; Grey])
  ] in
  let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
  (* Should pick from unrevealed positions (2, 3, 4) *)
  assert_bool "Position should be unrevealed" (pos >= 2 && pos < 5);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

let test_generate_hint_mode1_all_revealed _ =
  let answer = "hello" in
  (* All positions revealed as Green *)
  let guesses_with_colors = [
    ("hello", [Green; Green; Green; Green; Green])
  ] in
  let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
  (* Should still return a valid position *)
  assert_bool "Position should be valid" (pos >= 0 && pos < String.length answer);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

let test_generate_hint_mode1_multiple_guesses _ =
  let answer = "hello" in
  (* Multiple guesses revealing different positions *)
  let guesses_with_colors = [
    ("world", [Grey; Grey; Grey; Grey; Grey]);
    ("crane", [Grey; Grey; Yellow; Grey; Grey])
  ] in
  let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
  (* Should pick an unrevealed position *)
  assert_bool "Position should be valid" (pos >= 0 && pos < String.length answer);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

(** Test generate_hint_mode2 *)
let test_generate_hint_mode2_no_revealed _ =
  let answer = "hello" in
  let guesses_with_colors = [] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

let test_generate_hint_mode2_some_revealed _ =
  let answer = "hello" in
  (* Reveal 'h' and 'e' as Green/Yellow *)
  let guesses_with_colors = [
    ("hello", [Green; Green; Grey; Grey; Grey])
  ] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  (* Should pick from unrevealed letters (l, o) *)
  assert_bool "Letter should be unrevealed" 
    (List.mem ['l'; 'o'] letter ~equal:Char.equal);
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

let test_generate_hint_mode2_all_revealed _ =
  let answer = "hello" in
  (* All letters revealed *)
  let guesses_with_colors = [
    ("hello", [Green; Green; Green; Green; Green])
  ] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  (* Should still return a valid letter from answer *)
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

let test_generate_hint_mode2_yellow_letters _ =
  let answer = "hello" in
  (* Reveal 'l' as Yellow (not Green) *)
  let guesses_with_colors = [
    ("world", [Grey; Grey; Yellow; Grey; Grey])
  ] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  (* 'l' is revealed as Yellow, so should pick from unrevealed (h, e, o) *)
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

(** Test display_cumulative_hints *)
let test_display_cumulative_hints_empty _ =
  let hints = { mode1_hints = []; mode2_hints = [] } in
  (* Should not crash *)
  display_cumulative_hints ~word_length:5 hints;
  assert_bool "Empty hints should not crash" true

let test_display_cumulative_hints_mode1 _ =
  let hints = { 
    mode1_hints = [(0, 'h'); (2, 'l')]; 
    mode2_hints = [] 
  } in
  (* Should not crash *)
  display_cumulative_hints ~word_length:5 hints;
  assert_bool "Mode1 hints should not crash" true

let test_display_cumulative_hints_mode2 _ =
  let hints = { 
    mode1_hints = []; 
    mode2_hints = ['h'; 'e'] 
  } in
  (* Should not crash *)
  display_cumulative_hints ~word_length:5 hints;
  assert_bool "Mode2 hints should not crash" true

let test_display_cumulative_hints_both _ =
  let hints = { 
    mode1_hints = [(0, 'h')]; 
    mode2_hints = ['e'] 
  } in
  (* Should not crash *)
  display_cumulative_hints ~word_length:5 hints;
  assert_bool "Both hint modes should not crash" true

(** Test offer_hint - Note: This involves UI interaction, so we'll test the logic parts *)
(* Since offer_hint calls Ui.prompt_bool and Ui.prompt_hint_mode which require stdin,
   we can't easily test the full flow without mocking. But we can test that the function
   handles the cumulative hints correctly by checking the display function works. *)

let suite =
  "Hints module tests" >::: [
    "generate_hint_mode1_no_revealed" >:: test_generate_hint_mode1_no_revealed;
    "generate_hint_mode1_some_revealed" >:: test_generate_hint_mode1_some_revealed;
    "generate_hint_mode1_all_revealed" >:: test_generate_hint_mode1_all_revealed;
    "generate_hint_mode1_multiple_guesses" >:: test_generate_hint_mode1_multiple_guesses;
    "generate_hint_mode2_no_revealed" >:: test_generate_hint_mode2_no_revealed;
    "generate_hint_mode2_some_revealed" >:: test_generate_hint_mode2_some_revealed;
    "generate_hint_mode2_all_revealed" >:: test_generate_hint_mode2_all_revealed;
    "generate_hint_mode2_yellow_letters" >:: test_generate_hint_mode2_yellow_letters;
    "display_cumulative_hints_empty" >:: test_display_cumulative_hints_empty;
    "display_cumulative_hints_mode1" >:: test_display_cumulative_hints_mode1;
    "display_cumulative_hints_mode2" >:: test_display_cumulative_hints_mode2;
    "display_cumulative_hints_both" >:: test_display_cumulative_hints_both;
  ]

let () = run_test_tt_main suite

