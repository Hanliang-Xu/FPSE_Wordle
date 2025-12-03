(** Game loop module for running the Wordle game *)

open Core

(** Run the game with a given configuration *)
let run_with_config ~word_length ~max_guesses ~show_hints ~feedback_granularity ~show_position_distances =
  let module Config = struct
    let word_length = word_length
    let feedback_granularity = feedback_granularity
    let show_position_distances = show_position_distances
  end in
  let module W = Lib.Wordle_functor.Make (Config) in
  (* Load words from Random Word API only (no local file fallback) and answers from local files *)
  Printf.printf "Loading words from Random Word API... ";
  Out_channel.flush stdout;
  let words_dict, answers_dict = Lib.Dict.load_dictionary_by_length_api Config.word_length in
  Printf.printf "Done!\n";
  let answer = Lib.Dict.normalize_word (Lib.Dict.get_random_word answers_dict) in
  let show_hint_if_enabled ~solver_guess =
    if show_hints then
      Printf.printf "Hint (solver's guess): %s\n" solver_guess
  in
  let game = W.Game.init ~answer ~max_guesses in
  let solver = W.Solver.create words_dict in
  let initial_hints = { Hints.mode1_hints = []; Hints.mode2_hints = [] } in
  
  (* Game loop - continue while game is not over *)
  let rec loop game_state solver_state cumulative_hints =
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
        let candidate_count = W.Solver.candidate_count solver_state in
        show_hint_if_enabled ~solver_guess;
        if show_hints then
          Printf.printf "Solver: %d candidate words remaining\n" candidate_count;
        
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
          (* Check if word is valid using API *)
          Printf.printf "Validating word via API... ";
          Out_channel.flush stdout;
          if not (Lib.Dict.is_valid_word_api valid_guess) then (
            Printf.printf "Invalid word: %s is not a valid word\n" valid_guess;
            loop game_state solver_state cumulative_hints
          ) else (
            Printf.printf "Valid!\n";
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
            let new_candidate_count = W.Solver.candidate_count new_solver_state in
            
            (* Display current state *)
            Printf.printf "Guess %d/%d: %s\n" 
              (W.Game.num_guesses new_game_state)
              (W.Game.max_guesses new_game_state)
              (W.Guess.to_string feedback);
            
            (* Show solver progress if hints enabled *)
            if show_hints then
              Printf.printf "Solver: %d candidate words remaining (filtered from %d)\n" 
                new_candidate_count (W.Solver.candidate_count solver_state);
            
            (* Check if the guess was correct (all green) *)
            if W.Game.is_won new_game_state then (
              Printf.printf "Congratulations! You guessed it in %d time%s!\n" 
                (W.Game.num_guesses new_game_state)
                (if W.Game.num_guesses new_game_state = 1 then "" else "s")
            ) else (
              Printf.printf "Remaining guesses: %d\n" 
                (W.Game.remaining_guesses new_game_state);
              Printf.printf "\n";
              
              (* Offer hint to user only if game is not won *)
              let current_board = W.Game.get_board new_game_state in
              (* Extract guess and colors from feedback for hint generation *)
              let guesses_with_colors = 
                List.map current_board ~f:(fun fb -> 
                  (* Access feedback fields - feedback is Feedback.feedback type *)
                  let open Lib.Feedback in
                  (fb.guess, fb.colors)
                )
              in
              let updated_hints = Hints.offer_hint ~answer ~guesses_with_colors ~cumulative_hints in
              Printf.printf "\n";
              
              (* Continue loop only if game is not won *)
              loop new_game_state new_solver_state updated_hints
            )
          )
        | Error msg ->
          Printf.printf "Invalid guess: %s\n" msg;
          loop game_state solver_state cumulative_hints
      ) else (
        (* Should not happen if is_over is correct, but handle gracefully *)
        loop game_state solver_state cumulative_hints
      )
    )
  in
  
  (* Print game info *)
  Printf.printf "Loaded %d valid words\n" (Lib.Dict.word_count words_dict);
  Printf.printf "Loaded %d possible answers\n" (Lib.Dict.word_count answers_dict);
  Printf.printf "Solver initialized with %d candidate words\n" (W.Solver.candidate_count solver);
  Printf.printf "Max guesses: %d\n" max_guesses;
  Printf.printf "Hints: %s\n" (if show_hints then "enabled" else "disabled");
  Printf.printf "Starting game!\n\n";
  
  loop game solver initial_hints

