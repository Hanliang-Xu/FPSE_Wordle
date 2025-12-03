(** Complex integration tests using multiple files and modules *)

open Core
open OUnit2

(** Test loading and using multiple dictionary files *)
let test_multiple_dictionary_files _ =
  let test_length length =
    let words, answers = Lib.Dict.load_dictionary_by_length length in
    assert_bool (Printf.sprintf "Should load words for length %d" length) 
      (List.length words > 0);
    assert_bool (Printf.sprintf "Should load answers for length %d" length) 
      (List.length answers > 0);
    assert_bool (Printf.sprintf "All words should be length %d" length)
      (List.for_all words ~f:(fun w -> String.length w = length));
    assert_bool (Printf.sprintf "All answers should be length %d" length)
      (List.for_all answers ~f:(fun w -> String.length w = length));
    assert_bool (Printf.sprintf "All answers should be in words for length %d" length)
      (List.for_all answers ~f:(fun a -> List.mem words a ~equal:String.equal))
  in
  List.iter [2; 3; 4; 5; 6; 7; 8; 9; 10] ~f:test_length

(** Test full game with real dictionaries *)
let test_full_game_with_real_dict _ =
  let module Config = struct
    let word_length = 5
    let feedback_granularity = Lib.Config.ThreeState
  end in
  let module W = Lib.Wordle_functor.Make (Config) in
  
  let words, answers = Lib.Dict.load_dictionary_by_length 5 in
  let answer = Lib.Dict.get_random_word answers in
  let game = W.Game.init ~answer ~max_guesses:6 in
  let solver = W.Solver.create words in
  
  (* Play multiple rounds *)
  let rec play_round game_state solver_state round =
    if W.Game.is_over game_state || round >= 6 then
      game_state
    else (
      let guess = W.Solver.make_guess solver_state in
      assert_bool "Guess should be valid length" 
        (W.Utils.validate_length guess);
      assert_bool "Guess should be in words list" 
        (Lib.Dict.is_valid_word guess words);
      
      let new_game_state = W.Game.step game_state guess in
      let feedback = match W.Game.last_feedback new_game_state with
        | Some fb -> fb
        | None -> assert_failure "Expected feedback"
      in
      let new_solver_state = W.Solver.update solver_state feedback in
      play_round new_game_state new_solver_state (round + 1)
    )
  in
  
  let final_game = play_round game solver 0 in
  assert_bool "Game should have made at least one guess" 
    (W.Game.num_guesses final_game > 0);
  assert_bool "Game should be over" 
    (W.Game.is_over final_game)

(** Test multiple word lengths with full game flow *)
let test_multiple_word_lengths_full_flow _ =

  let test_length length =
    let module Config = struct
      let word_length = length
      let feedback_granularity = Lib.Config.ThreeState
    end in
    let module W = Lib.Wordle_functor.Make (Config) in
    
    let words, answers = Lib.Dict.load_dictionary_by_length length in
    let answer = Lib.Dict.get_random_word answers in
    let game = W.Game.init ~answer ~max_guesses:5 in
    let solver = W.Solver.create words in
    
    let guess = W.Solver.make_guess solver in
    match W.Utils.validate_guess guess with
    | Ok valid_guess ->
        let game1 = W.Game.step game valid_guess in
        assert_equal 1 (W.Game.num_guesses game1);
        assert_bool "Guess should be correct length" 
          (String.length valid_guess = length)
    | Error _ -> assert_failure (Printf.sprintf "Guess should be valid for length %d" length)
  in
  List.iter [3; 4; 5; 6; 7] ~f:test_length

(** Test both feedback granularities with real dictionaries *)
let test_both_feedback_granularities _ =

  let _, answers = Lib.Dict.load_dictionary_by_length 5 in
  let answer = Lib.Dict.get_random_word answers in
  
  (* Three-state mode *)
  let module Config3 = struct
    let word_length = 5
    let feedback_granularity = Lib.Config.ThreeState
  end in
  let module W3 = Lib.Wordle_functor.Make (Config3) in
  
  (* Binary mode *)
  let module ConfigB = struct
    let word_length = 5
    let feedback_granularity = Lib.Config.Binary
  end in
  let module WB = Lib.Wordle_functor.Make (ConfigB) in
  
  let guess = "crane" in
  let game3 = W3.Game.init ~answer ~max_guesses:6 in
  let gameB = WB.Game.init ~answer ~max_guesses:6 in
  
  let game3_1 = W3.Game.step game3 guess in
  let gameB_1 = WB.Game.step gameB guess in
  
  let feedback3 = match W3.Game.last_feedback game3_1 with
    | Some fb -> fb
    | None -> assert_failure "Expected feedback"
  in
  let feedbackB = match WB.Game.last_feedback gameB_1 with
    | Some fb -> fb
    | None -> assert_failure "Expected feedback"
  in
  
  (* Three-state can have Yellow, binary cannot *)
  let _ = List.exists feedback3.colors ~f:(function
    | W3.Guess.Yellow -> true
    | _ -> false)
  in
  let has_yellowB = List.exists feedbackB.colors ~f:(function
    | WB.Guess.Yellow -> true
    | _ -> false)
  in
  assert_bool "Binary mode should not have Yellow" (not has_yellowB)
  (* Note: Three-state mode may or may not have yellow depending on guess/answer *)

(** Test cross-file validation *)
let test_cross_file_validation _ =

  (* Load words from multiple lengths *)
  let words3, _ = Lib.Dict.load_dictionary_by_length 3 in
  let words5, _ = Lib.Dict.load_dictionary_by_length 5 in
  let words7, _ = Lib.Dict.load_dictionary_by_length 7 in
  
  (* Verify they don't overlap inappropriately *)
  assert_bool "3-letter words should not be in 5-letter list" 
    (List.for_all words3 ~f:(fun w -> not (List.mem words5 w ~equal:String.equal)));
  assert_bool "5-letter words should not be in 3-letter list" 
    (List.for_all words5 ~f:(fun w -> not (List.mem words3 w ~equal:String.equal)));
  assert_bool "7-letter words should not be in 5-letter list" 
    (List.for_all words7 ~f:(fun w -> not (List.mem words5 w ~equal:String.equal)));
  ()

(** Test game with multiple configurations simultaneously *)
let test_multiple_configs_simultaneously _ =

  let module Config3 = struct
    let word_length = 3
    let feedback_granularity = Lib.Config.ThreeState
  end in
  let module Config5 = struct
    let word_length = 5
    let feedback_granularity = Lib.Config.ThreeState
  end in
  let module Config7 = struct
    let word_length = 7
    let feedback_granularity = Lib.Config.Binary
  end in
  let module W3 = Lib.Wordle_functor.Make (Config3) in
  let module W5 = Lib.Wordle_functor.Make (Config5) in
  let module W7 = Lib.Wordle_functor.Make (Config7) in
  
  let words3, answers3 = Lib.Dict.load_dictionary_by_length 3 in
  let words5, answers5 = Lib.Dict.load_dictionary_by_length 5 in
  let words7, answers7 = Lib.Dict.load_dictionary_by_length 7 in
  
  let answer3 = Lib.Dict.get_random_word answers3 in
  let answer5 = Lib.Dict.get_random_word answers5 in
  let answer7 = Lib.Dict.get_random_word answers7 in
  
  let game3 = W3.Game.init ~answer:answer3 ~max_guesses:5 in
  let game5 = W5.Game.init ~answer:answer5 ~max_guesses:6 in
  let game7 = W7.Game.init ~answer:answer7 ~max_guesses:7 in
  
  let solver3 = W3.Solver.create words3 in
  let solver5 = W5.Solver.create words5 in
  let solver7 = W7.Solver.create words7 in
  
  let guess3 = W3.Solver.make_guess solver3 in
  let guess5 = W5.Solver.make_guess solver5 in
  let guess7 = W7.Solver.make_guess solver7 in
  
  assert_bool "3-letter guess should be valid" (W3.Utils.validate_length guess3);
  assert_bool "5-letter guess should be valid" (W5.Utils.validate_length guess5);
  assert_bool "7-letter guess should be valid" (W7.Utils.validate_length guess7);
  
  let game3_1 = W3.Game.step game3 guess3 in
  let game5_1 = W5.Game.step game5 guess5 in
  let game7_1 = W7.Game.step game7 guess7 in
  
  assert_equal 1 (W3.Game.num_guesses game3_1);
  assert_equal 1 (W5.Game.num_guesses game5_1);
  assert_equal 1 (W7.Game.num_guesses game7_1)

let suite =
  "Integration tests" >::: [
    "multiple_dictionary_files" >:: test_multiple_dictionary_files;
    "full_game_with_real_dict" >:: test_full_game_with_real_dict;
    "multiple_word_lengths_full_flow" >:: test_multiple_word_lengths_full_flow;
    "both_feedback_granularities" >:: test_both_feedback_granularities;
    "cross_file_validation" >:: test_cross_file_validation;
    "multiple_configs_simultaneously" >:: test_multiple_configs_simultaneously;
  ]

let () = run_test_tt_main suite

