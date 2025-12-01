open Core
open OUnit2

(** Mock Guess module for testing Game module *)
module MockGuess = struct
  include Lib.Feedback
  
  (** Simple mock implementation: 
      - If guess equals answer, all Green
      - Otherwise, all Grey *)
  let generate guess answer =
    if String.equal guess answer then
      List.init (String.length guess) ~f:(fun _ -> Lib.Feedback.Green)
    else
      List.init (String.length guess) ~f:(fun _ -> Lib.Feedback.Grey)
  
  let make_feedback guess answer =
    {
      guess;
      colors = generate guess answer;
    }
  
  let is_correct feedback =
    List.for_all feedback.colors ~f:(fun c -> match c with
      | Lib.Feedback.Green -> true
      | _ -> false)
  
  let color_to_string = function
    | Lib.Feedback.Green -> "Green"
    | Lib.Feedback.Yellow -> "Yellow"
    | Lib.Feedback.Grey -> "Grey"
  
  let to_string feedback =
    Printf.sprintf "%s: %s" feedback.guess
      (String.concat ~sep:" " (List.map feedback.colors ~f:color_to_string))
  
  let colors_to_string colors =
    String.concat ~sep:" " (List.map colors ~f:color_to_string)
end

(** Create Game module instance with mock Guess *)
module Game = Lib.Game.Make (MockGuess)

(** Test suite for Game module *)

let test_init _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  assert_equal 0 (Game.num_guesses game);
  assert_equal 6 (Game.max_guesses game);
  assert_equal [] (Game.get_board game);
  assert_equal None (Game.last_feedback game);
  assert_equal false (Game.is_won game);
  assert_equal false (Game.is_over game);
  assert_equal true (Game.can_guess game);
  assert_equal 6 (Game.remaining_guesses game)

let test_step _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  let game1 = Game.step game "world" in
  assert_equal 1 (Game.num_guesses game1);
  assert_equal 5 (Game.remaining_guesses game1);
  assert_equal false (Game.is_won game1);
  assert_equal false (Game.is_over game1);
  assert_equal true (Game.can_guess game1);
  
  (* Check that feedback was generated *)
  match Game.last_feedback game1 with
  | Some fb ->
      assert_equal "world" fb.guess;
      assert_equal 5 (List.length fb.colors)
  | None -> assert_failure "Expected feedback after step"

let test_step_correct_guess _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  let game1 = Game.step game "hello" in
  assert_equal 1 (Game.num_guesses game1);
  assert_equal true (Game.is_won game1);
  assert_equal true (Game.is_over game1);
  assert_equal false (Game.can_guess game1);
  
  (* Check that feedback shows all Green *)
  match Game.last_feedback game1 with
  | Some fb ->
      assert_equal "hello" fb.guess;
      assert_bool "All colors should be Green for correct guess"
        (List.for_all fb.colors ~f:(fun c -> match c with
          | Lib.Feedback.Green -> true
          | _ -> false))
  | None -> assert_failure "Expected feedback after step"

let test_multiple_steps _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  let game1 = Game.step game "world" in
  let game2 = Game.step game1 "test" in
  let game3 = Game.step game2 "hello" in
  
  assert_equal 3 (Game.num_guesses game3);
  assert_equal 3 (Game.remaining_guesses game3);
  assert_equal true (Game.is_won game3);
  assert_equal true (Game.is_over game3);
  
  (* Check board contains all guesses *)
  let board = Game.get_board game3 in
  assert_equal 3 (List.length board);
  assert_equal "world" (List.nth_exn board 0).guess;
  assert_equal "test" (List.nth_exn board 1).guess;
  assert_equal "hello" (List.nth_exn board 2).guess

let test_num_guesses _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  assert_equal 0 (Game.num_guesses game);
  
  let game1 = Game.step game "world" in
  assert_equal 1 (Game.num_guesses game1);
  
  let game2 = Game.step game1 "test" in
  assert_equal 2 (Game.num_guesses game2);
  
  let game3 = Game.step game2 "word" in
  assert_equal 3 (Game.num_guesses game3)

let test_is_won _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  assert_equal false (Game.is_won game);
  
  let game1 = Game.step game "world" in
  assert_equal false (Game.is_won game1);
  
  let game2 = Game.step game1 "hello" in
  assert_equal true (Game.is_won game2)

let test_get_board _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  assert_equal [] (Game.get_board game);
  
  let game1 = Game.step game "world" in
  let board1 = Game.get_board game1 in
  assert_equal 1 (List.length board1);
  assert_equal "world" (List.hd_exn board1).guess;
  
  let game2 = Game.step game1 "test" in
  let board2 = Game.get_board game2 in
  assert_equal 2 (List.length board2)

let test_last_feedback _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  assert_equal None (Game.last_feedback game);
  
  let game1 = Game.step game "world" in
  (match Game.last_feedback game1 with
  | Some fb -> assert_equal "world" fb.guess
  | None -> assert_failure "Expected feedback after step");
  
  let game2 = Game.step game1 "test" in
  match Game.last_feedback game2 with
  | Some fb -> assert_equal "test" fb.guess
  | None -> assert_failure "Expected feedback after step"

let test_remaining_guesses _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  assert_equal 6 (Game.remaining_guesses game);
  
  let game1 = Game.step game "world" in
  assert_equal 5 (Game.remaining_guesses game1);
  
  let game2 = Game.step game1 "test" in
  assert_equal 4 (Game.remaining_guesses game2);
  
  let game3 = Game.step game2 "word" in
  assert_equal 3 (Game.remaining_guesses game3);
  
  let game4 = Game.step game3 "code" in
  assert_equal 2 (Game.remaining_guesses game4);
  
  let game5 = Game.step game4 "play" in
  assert_equal 1 (Game.remaining_guesses game5);
  
  let game6 = Game.step game5 "game" in
  assert_equal 0 (Game.remaining_guesses game6)

let test_max_guesses _ =
  let game1 = Game.init ~answer:"hello" ~max_guesses:3 in
  assert_equal 3 (Game.max_guesses game1);
  
  let game2 = Game.init ~answer:"world" ~max_guesses:6 in
  assert_equal 6 (Game.max_guesses game2);
  
  let game3 = Game.init ~answer:"test" ~max_guesses:10 in
  assert_equal 10 (Game.max_guesses game3)

let test_is_over _ =
  let game = Game.init ~answer:"hello" ~max_guesses:3 in
  assert_equal false (Game.is_over game);
  
  (* Game over by winning *)
  let game1 = Game.step game "hello" in
  assert_equal true (Game.is_over game1);
  
  (* Game over by max guesses *)
  let game2 = Game.init ~answer:"world" ~max_guesses:2 in
  let game3 = Game.step game2 "test" in
  assert_equal false (Game.is_over game3);
  let game4 = Game.step game3 "code" in
  assert_equal true (Game.is_over game4);
  assert_equal false (Game.is_won game4)

let test_can_guess _ =
  let game = Game.init ~answer:"hello" ~max_guesses:3 in
  assert_equal true (Game.can_guess game);
  
  (* Can guess after one step *)
  let game1 = Game.step game "world" in
  assert_equal true (Game.can_guess game1);
  
  (* Cannot guess after winning *)
  let game2 = Game.step game1 "hello" in
  assert_equal false (Game.can_guess game2);
  
  (* Cannot guess after max guesses *)
  let game3 = Game.init ~answer:"world" ~max_guesses:2 in
  let game4 = Game.step game3 "test" in
  assert_equal true (Game.can_guess game4);
  let game5 = Game.step game4 "code" in
  assert_equal false (Game.can_guess game5)

let test_max_guesses_reached _ =
  let game = Game.init ~answer:"hello" ~max_guesses:2 in
  let game1 = Game.step game "world" in
  assert_equal false (Game.is_over game1);
  assert_equal true (Game.can_guess game1);
  
  let game2 = Game.step game1 "test" in
  assert_equal true (Game.is_over game2);
  assert_equal false (Game.can_guess game2);
  assert_equal false (Game.is_won game2);
  assert_equal 0 (Game.remaining_guesses game2)

let test_answer_stored _ =
  let game = Game.init ~answer:"hello" ~max_guesses:6 in
  (* Answer should be stored and used for feedback generation *)
  let game1 = Game.step game "hello" in
  assert_equal true (Game.is_won game1);
  
  (* Different answer *)
  let game2 = Game.init ~answer:"world" ~max_guesses:6 in
  let game3 = Game.step game2 "hello" in
  assert_equal false (Game.is_won game3);
  let game4 = Game.step game3 "world" in
  assert_equal true (Game.is_won game4)

let suite =
  "Game module tests" >::: [
    "init" >:: test_init;
    "step" >:: test_step;
    "step_correct_guess" >:: test_step_correct_guess;
    "multiple_steps" >:: test_multiple_steps;
    "num_guesses" >:: test_num_guesses;
    "is_won" >:: test_is_won;
    "get_board" >:: test_get_board;
    "last_feedback" >:: test_last_feedback;
    "remaining_guesses" >:: test_remaining_guesses;
    "max_guesses" >:: test_max_guesses;
    "is_over" >:: test_is_over;
    "can_guess" >:: test_can_guess;
    "max_guesses_reached" >:: test_max_guesses_reached;
    "answer_stored" >:: test_answer_stored;
  ]

let () = run_test_tt_main suite

