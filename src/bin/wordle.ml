(** Main entry point for Wordle game *)

open Core

(** Configuration for a 5-letter Wordle game *)
module Config = struct
  let word_length = 5
end

(** Create a Wordle game instance with the configuration *)
module W = Lib.Wordle_functor.Make (Config)

(** Load dictionaries from data files *)
let load_dictionaries () =
  let words_dict = Lib.Dict.load_dictionary "data/words.txt" in
  let answers_dict = Lib.Dict.load_dictionary "data/answers.txt" in
  (words_dict, answers_dict)

(** Main game loop skeleton - demonstrates how modules thread together *)
let play_game ~answer ~max_guesses ~words_dict =
  (* Normalize answer for consistency *)
  let answer = Lib.Dict.normalize_word answer in
  
  (* Initialize game state *)
  let game = W.Game.init ~max_guesses in
  
  (* Initialize solver with the words dictionary *)
  let solver = W.Solver.create words_dict in
  
  (* Game loop - continue while game is not over *)
  let rec loop game_state solver_state =
    (* Check if game is over *)
    if W.Game.is_over game_state then (
      (* Game ended - check if won *)
      if W.Game.is_won game_state then
        Printf.printf "Congratulations! You won!\n"
      else
        Printf.printf "Game over! The answer was: %s\n" answer;
      (* Display final board *)
      let board = W.Game.get_board game_state in
      List.iter board ~f:(fun fb -> 
        Printf.printf "%s\n" (W.Guess.to_string fb)
      )
    ) else (
      (* Game still active - check if we can make a guess *)
      if W.Game.can_guess game_state then (
        (* Get guess from solver or user input *)
        let guess = W.Solver.make_guess solver_state in
        
        (* Normalize guess for consistency *)
        let normalized_guess = Lib.Dict.normalize_word guess in
        
        (* Validate the guess using Utils *)
        match W.Utils.validate_guess normalized_guess with
        | Ok valid_guess ->
          (* Check if word is in dictionary *)
          if not (Lib.Dict.is_valid_word valid_guess words_dict) then (
            Printf.printf "Invalid word: %s is not in the dictionary\n" valid_guess;
            loop game_state solver_state
          ) else (
            (* Generate feedback for the guess *)
            let feedback = W.Guess.make_feedback valid_guess answer in
            
            (* Update game state with the new guess *)
            let new_game_state = W.Game.step game_state valid_guess in
            
            (* Update solver with feedback *)
            let new_solver_state = W.Solver.update solver_state feedback.guess feedback.colors in
            
            (* Display current state *)
            Printf.printf "Guess %d/%d: %s\n" 
              (W.Game.num_guesses new_game_state)
              (W.Game.max_guesses new_game_state)
              (W.Guess.to_string feedback);
            Printf.printf "Remaining guesses: %d\n" 
              (W.Game.remaining_guesses new_game_state);
            
            (* Continue loop *)
            loop new_game_state new_solver_state
          )
        | Error msg ->
          Printf.printf "Invalid guess: %s\n" msg;
          loop game_state solver_state
      ) else (
        (* Should not happen if is_over is correct, but handle gracefully *)
        loop game_state solver_state
      )
    )
  in
  
  loop game solver

(** Main entry point *)
let main () =
  (* Load dictionaries *)
  let words_dict, answers_dict = load_dictionaries () in
  
  (* Get a random answer from the answers dictionary *)
  let answer = Lib.Dict.get_random_word answers_dict in
  
  (* Print some info *)
  Printf.printf "Loaded %d valid words\n" (Lib.Dict.word_count words_dict);
  Printf.printf "Loaded %d possible answers\n" (Lib.Dict.word_count answers_dict);
  Printf.printf "Starting game with answer: %s\n\n" answer;
  
  let max_guesses = 6 in
  play_game ~answer ~max_guesses ~words_dict

let () = main ()

