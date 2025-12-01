(** Main entry point for Wordle game *)

open Core

(** Prompt user for a configuration value *)
let prompt_int ~default ~min ~max prompt =
  Printf.printf "%s [default: %d]: " prompt default;
  Out_channel.flush stdout;
  match In_channel.input_line In_channel.stdin with
  | None -> default
  | Some input ->
      let trimmed = String.strip input in
      if String.is_empty trimmed then default
      else
        match Int.of_string trimmed with
        | n when n >= min && n <= max -> n
        | _ ->
            Printf.printf "Invalid input. Using default: %d\n" default;
            default

let prompt_bool ~default prompt =
  Printf.printf "%s [default: %s] (y/n): " prompt (if default then "yes" else "no");
  Out_channel.flush stdout;
  match In_channel.input_line In_channel.stdin with
  | None -> default
  | Some input ->
      let trimmed = String.lowercase (String.strip input) in
      if String.is_empty trimmed then default
      else if String.equal trimmed "y" || String.equal trimmed "yes" then true
      else if String.equal trimmed "n" || String.equal trimmed "no" then false
      else (
        Printf.printf "Invalid input. Using default: %s\n" (if default then "yes" else "no");
        default
      )

(** Get configuration from user input *)
let get_config () =
  Printf.printf "\n=== Wordle Configuration ===\n";
  let word_length = prompt_int ~default:5 ~min:2 ~max:10 "Word length (2-10)" in
  let max_guesses = prompt_int ~default:6 ~min:1 ~max:20 "Max guesses" in
  let show_hints = prompt_bool ~default:true "Show hints (solver's guess)" in
  Printf.printf "\n";
  (word_length, max_guesses, show_hints)

(** Run the game with a given configuration *)
let run_with_config ~word_length ~max_guesses ~show_hints =
  let module Config = struct
    let word_length = word_length
  end in
  let module W = Lib.Wordle_functor.Make (Config) in
  let words_dict, answers_dict = Lib.Dict.load_dictionary_by_length Config.word_length in
  let answer = Lib.Dict.normalize_word (Lib.Dict.get_random_word answers_dict) in
  let show_hint_if_enabled ~solver_guess =
    if show_hints then
      Printf.printf "Hint (solver's guess): %s\n" solver_guess
  in
  let game = W.Game.init ~answer ~max_guesses in
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
        (* Get solver's guess for hint (if enabled) *)
        let solver_guess = W.Solver.make_guess solver_state in
        show_hint_if_enabled ~solver_guess;
        
        (* Get guess from user input *)
        Printf.printf "Enter your guess: ";
        Out_channel.flush stdout;
        let user_input = In_channel.input_line In_channel.stdin in
        let guess = match user_input with
          | None -> failwith "Unexpected end of input"
          | Some input -> input
        in
        
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
            (* Update game state with the new guess (feedback generated internally) *)
            let new_game_state = W.Game.step game_state valid_guess in
            
            (* Get the feedback for display and solver update *)
            let feedback =
              match W.Game.last_feedback new_game_state with
              | Some fb -> fb
              | None -> failwith "Unexpected: no feedback after step"
            in
            
            (* Update solver with feedback *)
            let new_solver_state = W.Solver.update solver_state feedback in
            
            (* Display current state *)
            Printf.printf "Guess %d/%d: %s\n" 
              (W.Game.num_guesses new_game_state)
              (W.Game.max_guesses new_game_state)
              (W.Guess.to_string feedback);
            Printf.printf "Remaining guesses: %d\n" 
              (W.Game.remaining_guesses new_game_state);
            Printf.printf "\n";
            
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
  
  (* Print game info *)
  Printf.printf "Loaded %d valid words\n" (Lib.Dict.word_count words_dict);
  Printf.printf "Loaded %d possible answers\n" (Lib.Dict.word_count answers_dict);
  Printf.printf "Max guesses: %d\n" max_guesses;
  Printf.printf "Hints: %s\n" (if show_hints then "enabled" else "disabled");
  Printf.printf "Starting game!\n\n";
  
  loop game solver

(** Main entry point *)
let main () =
  (* Get configuration from user *)
  let word_length, max_guesses, show_hints = get_config () in
  
  (* Run the game with the configuration *)
  run_with_config ~word_length ~max_guesses ~show_hints

let () = main ()

