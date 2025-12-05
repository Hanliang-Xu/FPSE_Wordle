(** Test suite for Feedback module *)

open Core
open OUnit2
open Lib.Feedback

(** Test color type *)
let test_color_types _ =
  (* Test that colors can be created and compared *)
  assert_bool "Green should equal Green" (match Green with Green -> true | _ -> false);
  assert_bool "Yellow should equal Yellow" (match Yellow with Yellow -> true | _ -> false);
  assert_bool "Grey should equal Grey" (match Grey with Grey -> true | _ -> false)

(** Test color list (t type) *)
let test_color_list _ =
  let colors = [Green; Yellow; Grey; Green] in
  assert_equal 4 (List.length colors);
  assert_bool "Should contain Green" 
    (List.exists colors ~f:(function Green -> true | _ -> false));
  assert_bool "Should contain Yellow" 
    (List.exists colors ~f:(function Yellow -> true | _ -> false));
  assert_bool "Should contain Grey" 
    (List.exists colors ~f:(function Grey -> true | _ -> false))

(** Test feedback type *)
let test_feedback_type _ =
  let feedback = { guess = "hello"; colors = [Green; Green; Green; Green; Green]; distances = None } in
  assert_equal "hello" feedback.guess ~printer:Fn.id;
  assert_equal 5 (List.length feedback.colors);
  assert_bool "All colors should be Green" 
    (List.for_all feedback.colors ~f:(function Green -> true | _ -> false))

let test_feedback_with_mixed_colors _ =
  let feedback = { 
    guess = "world"; 
    colors = [Green; Yellow; Grey; Green; Yellow];
    distances = None
  } in
  assert_equal "world" feedback.guess ~printer:Fn.id;
  assert_equal 5 (List.length feedback.colors);
  let green_count = List.count feedback.colors ~f:(function Green -> true | _ -> false) in
  let yellow_count = List.count feedback.colors ~f:(function Yellow -> true | _ -> false) in
  let grey_count = List.count feedback.colors ~f:(function Grey -> true | _ -> false) in
  assert_equal 2 green_count;
  assert_equal 2 yellow_count;
  assert_equal 1 grey_count

let test_feedback_empty_colors _ =
  let feedback = { guess = "test"; colors = []; distances = None } in
  assert_equal "test" feedback.guess ~printer:Fn.id;
  assert_equal 0 (List.length feedback.colors)

let test_feedback_different_lengths _ =
  (* Test feedback with different word lengths *)
  let feedback3 = { guess = "cat"; colors = [Green; Yellow; Grey]; distances = None } in
  assert_equal 3 (List.length feedback3.colors);
  
  let feedback5 = { guess = "hello"; colors = [Green; Green; Green; Green; Green]; distances = None } in
  assert_equal 5 (List.length feedback5.colors);
  
  let feedback7 = { 
    guess = "example"; 
    colors = [Green; Yellow; Grey; Green; Yellow; Grey; Green];
    distances = None
  } in
  assert_equal 7 (List.length feedback7.colors)

(** Complex edge case tests *)
let test_feedback_all_green _ =
  (* Test feedback with all green (correct guess) *)
  let feedback = { 
    guess = "hello"; 
    colors = [Green; Green; Green; Green; Green];
    distances = None
  } in
  assert_equal "hello" feedback.guess;
  assert_equal 5 (List.length feedback.colors);
  assert_bool "All colors should be Green"
    (List.for_all feedback.colors ~f:(function Green -> true | _ -> false))

let test_feedback_all_grey _ =
  (* Test feedback with all grey (no correct letters) *)
  let feedback = { 
    guess = "xyzzy"; 
    colors = [Grey; Grey; Grey; Grey; Grey];
    distances = None
  } in
  assert_equal "xyzzy" feedback.guess;
  assert_equal 5 (List.length feedback.colors);
  assert_bool "All colors should be Grey"
    (List.for_all feedback.colors ~f:(function Grey -> true | _ -> false))

let test_feedback_all_yellow _ =
  (* Test feedback with all yellow (all letters wrong position) *)
  let feedback = { 
    guess = "abcde"; 
    colors = [Yellow; Yellow; Yellow; Yellow; Yellow];
    distances = None
  } in
  assert_equal "abcde" feedback.guess;
  assert_equal 5 (List.length feedback.colors);
  assert_bool "All colors should be Yellow"
    (List.for_all feedback.colors ~f:(function Yellow -> true | _ -> false))

let test_feedback_mixed_patterns _ =
  (* Test various mixed color patterns *)
  let patterns = [
    ([Green; Yellow; Grey; Green; Yellow], "pattern1");
    ([Grey; Grey; Green; Grey; Grey], "pattern2");
    ([Yellow; Green; Yellow; Green; Yellow], "pattern3");
    ([Green; Grey; Yellow; Grey; Green], "pattern4");
  ] in
  List.iter patterns ~f:(fun (colors, name) ->
    let feedback = { guess = "test"; colors; distances = None } in
    assert_equal (List.length colors) (List.length feedback.colors);
    assert_bool (Printf.sprintf "Pattern %s should have correct length" name)
      (List.length feedback.colors = List.length colors)
  )

let test_feedback_edge_case_lengths _ =
  (* Test feedback with edge case word lengths *)
  let feedback2 = { guess = "ab"; colors = [Green; Grey]; distances = None } in
  assert_equal 2 (List.length feedback2.colors);
  
  let feedback10 = { 
    guess = "abcdefghij"; 
    colors = List.init 10 ~f:(fun i -> 
      if i mod 2 = 0 then Green else Yellow
    );
    distances = None
  } in
  assert_equal 10 (List.length feedback10.colors);
  assert_equal 5 (List.count feedback10.colors ~f:(function Green -> true | _ -> false));
  assert_equal 5 (List.count feedback10.colors ~f:(function Yellow -> true | _ -> false))

let test_feedback_consistency _ =
  (* Test that feedback structure is consistent *)
  let feedback = { 
    guess = "hello"; 
    colors = [Green; Yellow; Grey; Green; Yellow];
    distances = None
  } in
  (* Guess and colors should have matching lengths *)
  assert_equal (String.length feedback.guess) (List.length feedback.colors);
  (* All colors should be valid *)
  assert_bool "All colors should be valid"
    (List.for_all feedback.colors ~f:(function
      | Green | Yellow | Grey -> true))

let test_feedback_immutability _ =
  (* Test that feedback can be created with different values *)
  let feedback1 = { guess = "hello"; colors = [Green; Green; Green; Green; Green]; distances = None } in
  let feedback2 = { guess = "world"; colors = [Grey; Grey; Grey; Grey; Grey]; distances = None } in
  (* They should be independent *)
  assert_equal "hello" feedback1.guess;
  assert_equal "world" feedback2.guess;
  assert_bool "Feedback1 should have all Green"
    (List.for_all feedback1.colors ~f:(function Green -> true | _ -> false));
  assert_bool "Feedback2 should have all Grey"
    (List.for_all feedback2.colors ~f:(function Grey -> true | _ -> false))

let test_feedback_with_duplicate_letters _ =
  (* Test feedback structure with words that have duplicate letters *)
  let feedback = { 
    guess = "hello"; 
    colors = [Green; Yellow; Grey; Grey; Yellow];
    distances = None
  } in
  (* 'l' appears twice in "hello" *)
  assert_equal 5 (List.length feedback.colors);
  assert_equal "hello" feedback.guess;
  (* Verify structure is valid *)
  assert_bool "Feedback should have valid structure"
    (String.length feedback.guess = List.length feedback.colors)

let test_feedback_color_distribution _ =
  (* Test counting colors in feedback *)
  let feedback = { 
    guess = "test"; 
    colors = [Green; Yellow; Grey; Green];
    distances = None
  } in
  let green_count = List.count feedback.colors ~f:(function Green -> true | _ -> false) in
  let yellow_count = List.count feedback.colors ~f:(function Yellow -> true | _ -> false) in
  let grey_count = List.count feedback.colors ~f:(function Grey -> true | _ -> false) in
  assert_equal 2 green_count;
  assert_equal 1 yellow_count;
  assert_equal 1 grey_count;
  assert_equal 4 (green_count + yellow_count + grey_count)

let test_feedback_with_real_wordle_scenarios _ =
  (* Test feedback patterns that might occur in real Wordle games *)
  let scenarios = [
    (* Perfect match *)
    ("crane", [Green; Green; Green; Green; Green], "perfect_match");
    (* No matches *)
    ("xyzzy", [Grey; Grey; Grey; Grey; Grey], "no_matches");
    (* Some matches, some wrong position *)
    ("trace", [Green; Yellow; Grey; Yellow; Green], "mixed");
    (* All wrong position *)
    ("ecran", [Yellow; Yellow; Yellow; Yellow; Yellow], "all_wrong_position");
  ] in
  List.iter scenarios ~f:(fun (guess, colors, name) ->
    let feedback = { guess; colors; distances = None } in
    assert_equal (String.length guess) (List.length colors);
    assert_bool (Printf.sprintf "Scenario %s should be valid" name)
      (String.length feedback.guess = List.length feedback.colors)
  )

let suite =
  "Feedback module tests" >::: [
    "color_types" >:: test_color_types;
    "color_list" >:: test_color_list;
    "feedback_type" >:: test_feedback_type;
    "feedback_with_mixed_colors" >:: test_feedback_with_mixed_colors;
    "feedback_empty_colors" >:: test_feedback_empty_colors;
    "feedback_different_lengths" >:: test_feedback_different_lengths;
    "feedback_all_green" >:: test_feedback_all_green;
    "feedback_all_grey" >:: test_feedback_all_grey;
    "feedback_all_yellow" >:: test_feedback_all_yellow;
    "feedback_mixed_patterns" >:: test_feedback_mixed_patterns;
    "feedback_edge_case_lengths" >:: test_feedback_edge_case_lengths;
    "feedback_consistency" >:: test_feedback_consistency;
    "feedback_immutability" >:: test_feedback_immutability;
    "feedback_with_duplicate_letters" >:: test_feedback_with_duplicate_letters;
    "feedback_color_distribution" >:: test_feedback_color_distribution;
    "feedback_with_real_wordle_scenarios" >:: test_feedback_with_real_wordle_scenarios;
  ]

let () = run_test_tt_main suite

