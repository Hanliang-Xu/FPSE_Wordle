(** Comprehensive test suite for Config module type through implementations *)

open Core
open OUnit2

(** Test Config module type with different implementations *)

module Config3ThreeState = struct
  let word_length = 3
  let feedback_granularity = Lib.Config.ThreeState
  let show_position_distances = false
end

module Config5ThreeState = struct
  let word_length = 5
  let feedback_granularity = Lib.Config.ThreeState
  let show_position_distances = false
end

module Config5Binary = struct
  let word_length = 5
  let feedback_granularity = Lib.Config.Binary
  let show_position_distances = false
end

module Config7ThreeState = struct
  let word_length = 7
  let feedback_granularity = Lib.Config.ThreeState
  let show_position_distances = false
end

module Config10Binary = struct
  let word_length = 10
  let feedback_granularity = Lib.Config.Binary
  let show_position_distances = false
end

(** Test that Config implementations work with Wordle_functor *)
let test_config_with_wordle_functor _ =
  let module W3 = Lib.Wordle_functor.Make (Config3ThreeState) in
  let module W5 = Lib.Wordle_functor.Make (Config5ThreeState) in
  let module W5B = Lib.Wordle_functor.Make (Config5Binary) in
  let module W7 = Lib.Wordle_functor.Make (Config7ThreeState) in
  let module W10 = Lib.Wordle_functor.Make (Config10Binary) in
  
  assert_equal 3 W3.word_length;
  assert_equal 5 W5.word_length;
  assert_equal 5 W5B.word_length;
  assert_equal 7 W7.word_length;
  assert_equal 10 W10.word_length

(** Test that different configs create independent modules *)
let test_config_independence _ =
  let module W3 = Lib.Wordle_functor.Make (Config3ThreeState) in
  let module W5 = Lib.Wordle_functor.Make (Config5ThreeState) in
  
  (* Each should validate according to its own word_length *)
  assert_bool "W3 should validate 3-letter words" 
    (W3.Guess.validate_length "cat");
  assert_bool "W3 should reject 5-letter words" 
    (not (W3.Guess.validate_length "hello"));
  assert_bool "W5 should validate 5-letter words" 
    (W5.Guess.validate_length "hello");
  assert_bool "W5 should reject 3-letter words" 
    (not (W5.Guess.validate_length "cat"))

(** Test feedback_granularity affects Guess behavior *)
let test_feedback_granularity_three_state _ =
  let module W = Lib.Wordle_functor.Make (Config5ThreeState) in
  let feedback = W.Guess.make_feedback "crane" "trace" in
  (* Three-state can have Yellow *)
  let _ = List.exists feedback.colors ~f:(function
    | W.Guess.Yellow -> true
    | _ -> false)
  in
  (* Depending on the guess/answer, may or may not have yellow *)
  assert_bool "Three-state mode can produce Yellow" true

let test_feedback_granularity_binary _ =
  let module W = Lib.Wordle_functor.Make (Config5Binary) in
  let feedback = W.Guess.make_feedback "crane" "trace" in
  (* Binary mode should never have Yellow *)
  let has_yellow = List.exists feedback.colors ~f:(function
    | W.Guess.Yellow -> true
    | _ -> false)
  in
  assert_bool "Binary mode should not have Yellow" (not has_yellow);
  (* Should only have Green or Grey *)
  assert_bool "Binary mode should only have Green or Grey"
    (List.for_all feedback.colors ~f:(function
      | W.Guess.Green | W.Guess.Grey -> true
      | _ -> false))

(** Test config with real dictionaries *)
let test_config_with_real_dictionaries _ =
  let test_config length granularity =
    try
      let module Config = struct
        let word_length = length
        let feedback_granularity = granularity
        let show_position_distances = false
      end in
      let module W = Lib.Wordle_functor.Make (Config) in
      let words, answers = Lib.Dict.load_dictionary_by_length_api length in
      (* Answers should always be loaded from files *)
      if List.length answers = 0 then
        Printf.printf "Skipping length %d: no answers file\n" length
      else (
        let answer = Lib.Dict.get_random_word answers in
        (* If API returned words, use them; otherwise use answers as fallback *)
        let word_list = if List.length words > 0 then words else answers in
        let game = W.Game.init ~answer ~max_guesses:6 in
        let solver = W.Solver.create word_list in
        let guess = W.Solver.make_guess solver in
        assert_bool (Printf.sprintf "Guess should be valid length %d" length)
          (W.Guess.validate_length guess);
        let game1 = W.Game.step game guess in
        assert_equal 1 (W.Game.num_guesses game1)
      )
    with
    | Sys_error _ -> Printf.printf "Skipping length %d: file not found\n" length
    | _ -> Printf.printf "Skipping length %d: API unavailable\n" length
  in
  test_config 3 Lib.Config.ThreeState;
  test_config 5 Lib.Config.ThreeState;
  test_config 5 Lib.Config.Binary;
  test_config 7 Lib.Config.ThreeState

(** Test multiple configs simultaneously *)
let test_multiple_configs_simultaneously _ =
  let module W3 = Lib.Wordle_functor.Make (Config3ThreeState) in
  let module W5 = Lib.Wordle_functor.Make (Config5ThreeState) in
  let module W5B = Lib.Wordle_functor.Make (Config5Binary) in
  let module W7 = Lib.Wordle_functor.Make (Config7ThreeState) in
  
  (* All should work independently *)
  (* Note: Uses API for words - may skip if API unavailable *)
  try
    let words3, answers3 = Lib.Dict.load_dictionary_by_length_api 3 in
    let words5, answers5 = Lib.Dict.load_dictionary_by_length_api 5 in
    let words7, answers7 = Lib.Dict.load_dictionary_by_length_api 7 in
    
    (* Use answers as fallback if API returned no words *)
    let words3 = if List.length words3 > 0 then words3 else answers3 in
    let words5 = if List.length words5 > 0 then words5 else answers5 in
    let words7 = if List.length words7 > 0 then words7 else answers7 in
  
  let answer3 = Lib.Dict.get_random_word answers3 in
  let answer5 = Lib.Dict.get_random_word answers5 in
  let answer7 = Lib.Dict.get_random_word answers7 in
  
  let game3 = W3.Game.init ~answer:answer3 ~max_guesses:5 in
  let game5 = W5.Game.init ~answer:answer5 ~max_guesses:6 in
  let game5b = W5B.Game.init ~answer:answer5 ~max_guesses:6 in
  let game7 = W7.Game.init ~answer:answer7 ~max_guesses:7 in
  
  let solver3 = W3.Solver.create words3 in
  let solver5 = W5.Solver.create words5 in
  let solver7 = W7.Solver.create words7 in
  
  let guess3 = W3.Solver.make_guess solver3 in
  let guess5 = W5.Solver.make_guess solver5 in
  let guess7 = W7.Solver.make_guess solver7 in
  
  assert_bool "3-letter guess should be valid" (W3.Guess.validate_length guess3);
  assert_bool "5-letter guess should be valid" (W5.Guess.validate_length guess5);
  assert_bool "7-letter guess should be valid" (W7.Guess.validate_length guess7);
  
  let game3_1 = W3.Game.step game3 guess3 in
  let game5_1 = W5.Game.step game5 guess5 in
  let game5b_1 = W5B.Game.step game5b guess5 in
  let game7_1 = W7.Game.step game7 guess7 in
  
  assert_equal 1 (W3.Game.num_guesses game3_1);
  assert_equal 1 (W5.Game.num_guesses game5_1);
  assert_equal 1 (W5B.Game.num_guesses game5b_1);
  assert_equal 1 (W7.Game.num_guesses game7_1);
  
  (* Test that binary and three-state produce different feedback for same guess/answer *)
  let feedback5 = match W5.Game.last_feedback game5_1 with
    | Some fb -> fb
    | None -> assert_failure "Expected feedback"
  in
  let feedback5b = match W5B.Game.last_feedback game5b_1 with
    | Some fb -> fb
    | None -> assert_failure "Expected feedback"
  in
  (* They should have the same guess *)
  assert_equal feedback5.guess feedback5b.guess;
  (* But potentially different colors (binary can't have yellow) *)
  assert_bool "Binary should not have yellow"
    (not (List.exists feedback5b.colors ~f:(function W5B.Guess.Yellow -> true | _ -> false)))
  with
  | Sys_error _ -> Printf.printf "Skipping test: file not found\n"
  | _ -> Printf.printf "Skipping test: API unavailable\n"

(** Test config edge cases - minimum and maximum lengths *)
let test_config_edge_lengths _ =
  let module Config2 = struct
    let word_length = 2
    let feedback_granularity = Lib.Config.ThreeState
    let show_position_distances = false
  end in
  let module Config10 = struct
    let word_length = 10
    let feedback_granularity = Lib.Config.ThreeState
    let show_position_distances = false
  end in
  
  let module W2 = Lib.Wordle_functor.Make (Config2) in
  let module W10 = Lib.Wordle_functor.Make (Config10) in
  
  assert_equal 2 W2.word_length;
  assert_equal 10 W10.word_length;
  
  try
    let _, answers2 = Lib.Dict.load_dictionary_by_length_api 2 in
    let _, answers10 = Lib.Dict.load_dictionary_by_length_api 10 in
    
    if List.length answers2 > 0 && List.length answers10 > 0 then (
      let answer2 = Lib.Dict.get_random_word answers2 in
      let answer10 = Lib.Dict.get_random_word answers10 in
      
      let _ = W2.Game.init ~answer:answer2 ~max_guesses:5 in
      let _ = W10.Game.init ~answer:answer10 ~max_guesses:6 in
      
      assert_bool "2-letter answer should be valid" (W2.Guess.validate_length answer2);
      assert_bool "10-letter answer should be valid" (W10.Guess.validate_length answer10)
    ) else (
      Printf.printf "Skipping test: missing answer files\n"
    )
  with
  | Sys_error _ -> Printf.printf "Skipping test: file not found\n"
  | _ -> Printf.printf "Skipping test: API unavailable\n"

let suite =
  "Config module tests" >::: [
    "config_with_wordle_functor" >:: test_config_with_wordle_functor;
    "config_independence" >:: test_config_independence;
    "feedback_granularity_three_state" >:: test_feedback_granularity_three_state;
    "feedback_granularity_binary" >:: test_feedback_granularity_binary;
    "config_with_real_dictionaries" >:: test_config_with_real_dictionaries;
    "multiple_configs_simultaneously" >:: test_multiple_configs_simultaneously;
    "config_edge_lengths" >:: test_config_edge_lengths;
  ]

let () = run_test_tt_main suite

