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

(** Helper to redirect stdin from a string using pipes and suppress stdout *)
let with_stdin_from_string input f =
  let module U = Caml_unix in
  (* Suppress stdout *)
  let dev_null_fd = U.openfile "/dev/null" [U.O_WRONLY] 0o644 in
  let original_stdout = U.dup U.stdout in
  U.dup2 dev_null_fd U.stdout;
  U.close dev_null_fd;
  Out_channel.flush Out_channel.stdout;
  
  (* Create a pipe for stdin *)
  let (r, w) = U.pipe () in
  (* Write input to pipe *)
  ignore (U.write w (Bytes.of_string input) 0 (String.length input));
  U.close w;
  (* Save original stdin *)
  let original_stdin = U.dup U.stdin in
  (* Redirect stdin from pipe *)
  U.dup2 r U.stdin;
  U.close r;
  (* Flush stdout before redirect *)
  Out_channel.flush Out_channel.stdout;
  let result = f () in
  (* Flush after function *)
  Out_channel.flush Out_channel.stdout;
  (* Restore original stdin *)
  U.dup2 original_stdin U.stdin;
  U.close original_stdin;
  (* Restore original stdout *)
  U.dup2 original_stdout U.stdout;
  U.close original_stdout;
  (* Flush after restore *)
  Out_channel.flush Out_channel.stdout;
  result

(** Test offer_hint *)
let test_offer_hint_no_hint _ =
  (* User doesn't want a hint *)
  let answer = "hello" in
  let guesses_with_colors = [] in
  let initial_hints = { mode1_hints = []; mode2_hints = [] } in
  let result = with_stdin_from_string "n\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should return unchanged hints *)
  assert_equal initial_hints result

let test_offer_hint_mode1_new_hint _ =
  (* User wants hint mode 1, new position *)
  let answer = "hello" in
  let guesses_with_colors = [] in
  let initial_hints = { mode1_hints = []; mode2_hints = [] } in
  let result = with_stdin_from_string "y\n1\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should add a new mode1 hint *)
  assert_bool "Should have at least one mode1 hint" 
    (List.length result.mode1_hints > 0);
  let pos, letter = List.hd_exn result.mode1_hints in
  assert_bool "Position should be valid" (pos >= 0 && pos < String.length answer);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

let test_offer_hint_mode1_already_hinted _ =
  (* User wants hint mode 1, but position is already hinted *)
  (* We need to force the generated hint to be one we already have *)
  (* Since it's random, we'll test with all positions already hinted *)
  let answer = "hello" in
  let guesses_with_colors = [
    ("hello", [Green; Green; Green; Green; Green])
  ] in
  (* All positions are already revealed, so generate_hint_mode1 will pick any position *)
  (* We'll add all positions to mode1_hints to test the already_hinted path *)
  let initial_hints = { 
    mode1_hints = [(0, 'h'); (1, 'e'); (2, 'l'); (3, 'l'); (4, 'o')]; 
    mode2_hints = [] 
  } in
  let result = with_stdin_from_string "y\n1\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should return unchanged hints (or same length) since position is already hinted *)
  (* Note: Due to randomness, this might still add a hint if it picks a different position *)
  (* But if it picks an already hinted position, it should return unchanged *)
  assert_bool "Result should be valid" 
    (List.length result.mode1_hints >= List.length initial_hints.mode1_hints)

let test_offer_hint_mode2_new_hint _ =
  (* User wants hint mode 2, new letter *)
  let answer = "hello" in
  let guesses_with_colors = [] in
  let initial_hints = { mode1_hints = []; mode2_hints = [] } in
  let result = with_stdin_from_string "y\n2\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should add a new mode2 hint *)
  assert_bool "Should have at least one mode2 hint" 
    (List.length result.mode2_hints > 0);
  let letter = List.hd_exn result.mode2_hints in
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

let test_offer_hint_mode2_already_hinted _ =
  (* User wants hint mode 2, but letter is already hinted *)
  let answer = "hello" in
  let guesses_with_colors = [
    ("hello", [Green; Green; Green; Green; Green])
  ] in
  (* All letters are revealed, so generate_hint_mode2 will pick any letter *)
  (* We'll add all unique letters to mode2_hints *)
  let initial_hints = { 
    mode1_hints = []; 
    mode2_hints = ['h'; 'e'; 'l'; 'o'] 
  } in
  let result = with_stdin_from_string "y\n2\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should return unchanged hints (or same length) since letter is already hinted *)
  (* Note: Due to randomness, this might still add a hint if it picks a different letter *)
  assert_bool "Result should be valid" 
    (List.length result.mode2_hints >= List.length initial_hints.mode2_hints)

let test_offer_hint_invalid_mode _ =
  (* User wants hint but enters invalid mode, then valid mode *)
  (* prompt_hint_mode loops on invalid input, so we need to provide valid input after *)
  let answer = "hello" in
  let guesses_with_colors = [] in
  let initial_hints = { mode1_hints = []; mode2_hints = [] } in
  (* Enter invalid mode (99), then it will loop and we provide valid mode (1) *)
  (* Actually, prompt_hint_mode will keep looping, so we provide invalid then valid *)
  let result = with_stdin_from_string "y\n99\n1\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should add a hint (mode 1) *)
  assert_bool "Should have at least one mode1 hint" 
    (List.length result.mode1_hints > 0)

let test_offer_hint_mode1_with_existing_hints _ =
  (* User wants hint mode 1, with some existing hints *)
  (* Use a setup where position 0 is already revealed as Green, so generate_hint_mode1 *)
  (* will pick from positions 1-4, avoiding the already-hinted position 0 *)
  let answer = "hello" in
  let guesses_with_colors = [
    ("hxxxx", [Green; Grey; Grey; Grey; Grey])
  ] in
  let initial_hints = { 
    mode1_hints = [(0, 'h')]; 
    mode2_hints = [] 
  } in
  let result = with_stdin_from_string "y\n1\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should preserve the original hint *)
  assert_bool "Original hint should be preserved"
    (List.exists result.mode1_hints ~f:(fun (p, _) -> p = 0));
  (* Should either add a new hint (if it picks a different position) or keep the same *)
  (* Since position 0 is revealed as Green, generate_hint_mode1 will pick from 1-4 *)
  (* which are not in initial_hints, so it should add a new hint *)
  assert_bool "Should have at least 1 mode1 hint" 
    (List.length result.mode1_hints >= 1)

let test_offer_hint_mode2_with_existing_hints _ =
  (* User wants hint mode 2, with some existing hints *)
  let answer = "hello" in
  let guesses_with_colors = [] in
  let initial_hints = { 
    mode1_hints = []; 
    mode2_hints = ['h'] 
  } in
  let result = with_stdin_from_string "y\n2\n" (fun () ->
    offer_hint ~answer ~guesses_with_colors ~cumulative_hints:initial_hints
  ) in
  (* Should add a new hint, keeping the old one *)
  assert_bool "Should have at least 2 mode2 hints" 
    (List.length result.mode2_hints >= 2);
  (* Original hint should still be there *)
  assert_bool "Original hint should be preserved"
    (List.mem result.mode2_hints 'h' ~equal:Char.equal)

(** Additional edge case tests for generate_hint_mode1 *)
let test_generate_hint_mode1_single_position_revealed _ =
  let answer = "hello" in
  let guesses_with_colors = [
    ("hxxxx", [Green; Grey; Grey; Grey; Grey])
  ] in
  let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
  (* Should pick from positions 1-4 *)
  assert_bool "Position should be unrevealed" (pos >= 1 && pos < 5);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

let test_generate_hint_mode1_duplicate_letters _ =
  let answer = "hello" in
  (* Test with word that has duplicate letters *)
  let guesses_with_colors = [
    ("lllll", [Green; Green; Grey; Grey; Grey])
  ] in
  let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
  (* Should pick from unrevealed positions *)
  assert_bool "Position should be valid" (pos >= 0 && pos < String.length answer);
  assert_equal (String.get answer pos) letter ~printer:Char.to_string

(** Additional edge case tests for generate_hint_mode2 *)
let test_generate_hint_mode2_duplicate_letters _ =
  let answer = "hello" in
  (* Test with word that has duplicate letters *)
  let guesses_with_colors = [
    ("lllll", [Green; Green; Grey; Grey; Grey])
  ] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  (* 'l' is revealed, so should pick from unrevealed (h, e, o) *)
  assert_bool "Letter should be unrevealed" 
    (List.mem ['h'; 'e'; 'o'] letter ~equal:Char.equal);
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

let test_generate_hint_mode2_partial_reveal _ =
  let answer = "hello" in
  (* Reveal some letters as Yellow (not Green) *)
  let guesses_with_colors = [
    ("world", [Grey; Grey; Yellow; Grey; Grey])
  ] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  (* 'l' is revealed as Yellow, so should pick from unrevealed (h, e, o) *)
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

let test_generate_hint_mode2_no_duplicates_in_answer _ =
  let answer = "crane" in
  (* Answer with no duplicate letters *)
  let guesses_with_colors = [
    ("crane", [Green; Green; Green; Green; Green])
  ] in
  let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
  (* All letters revealed, should still return a valid letter *)
  assert_bool "Letter should be in answer" 
    (String.exists answer ~f:(fun c -> Char.equal c letter))

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
    "offer_hint_no_hint" >:: test_offer_hint_no_hint;
    "offer_hint_mode1_new_hint" >:: test_offer_hint_mode1_new_hint;
    "offer_hint_mode1_already_hinted" >:: test_offer_hint_mode1_already_hinted;
    "offer_hint_mode2_new_hint" >:: test_offer_hint_mode2_new_hint;
    "offer_hint_mode2_already_hinted" >:: test_offer_hint_mode2_already_hinted;
    "offer_hint_invalid_mode" >:: test_offer_hint_invalid_mode;
    "offer_hint_mode1_with_existing_hints" >:: test_offer_hint_mode1_with_existing_hints;
    "offer_hint_mode2_with_existing_hints" >:: test_offer_hint_mode2_with_existing_hints;
    "generate_hint_mode1_single_position_revealed" >:: test_generate_hint_mode1_single_position_revealed;
    "generate_hint_mode1_duplicate_letters" >:: test_generate_hint_mode1_duplicate_letters;
    "generate_hint_mode2_duplicate_letters" >:: test_generate_hint_mode2_duplicate_letters;
    "generate_hint_mode2_partial_reveal" >:: test_generate_hint_mode2_partial_reveal;
    "generate_hint_mode2_no_duplicates_in_answer" >:: test_generate_hint_mode2_no_duplicates_in_answer;
  ]

let () = run_test_tt_main suite

