(** Game loop module for running the Wordle game *)

open Core

(** Run the game with a given configuration *)
let run_with_config ~word_length ~max_guesses ~show_hints ~feedback_granularity ~show_position_distances =
  let module Config = struct
    let word_length = word_length
    let feedback_granularity = feedback_granularity
    let show_position_distances = show_position_distances
  end in
  let module W = Wordle_functor.Make (Config) in
  (* Load words from Random Word API only (no local file fallback) and answers from local files *)
  Printf.printf "Loading words from Random Word API... ";
  Out_channel.flush stdout;
  let words_dict, answers_dict = Dict.load_dictionary_by_length_api Config.word_length in
  Printf.printf "Done!\n";
  let answer = Dict.normalize_word (Dict.get_random_word answers_dict) in
  let game = W.Game.init ~answer ~max_guesses in
  let solver = W.Solver.create words_dict in
  let initial_hints = { Hints.mode1_hints = []; Hints.mode2_hints = [] } in
  
  (* Game loop - continue while game is not over *)
  let rec loop game_state solver_state cumulative_hints =
    (* Check if game is over *)
    if W.Game.is_over game_state then (
      (* Game ended - display results *)
      let human_won = W.Game.is_won game_state in
      let human_guesses = W.Game.num_guesses game_state in
      
      if human_won then
        Printf.printf "Congratulations! You won!\n"
      else
        Printf.printf "Game over! The answer was: %s\n" answer;
      
      (* Display final board *)
      let board = W.Game.get_board game_state in
      List.iter board ~f:(fun fb -> 
        Printf.printf "%s\n" (W.Guess.to_string fb)
      );
      
      Printf.printf "\n";
      Printf.printf "=== Competition Results ===\n";
      
      (* Run solver to completion *)
      Printf.printf "Running solver...\n";
      let solver_game = W.Game.init ~answer ~max_guesses in
      let solver_state = W.Solver.create words_dict in
      let rec solver_loop game_state solver_state =
        if W.Game.is_over game_state then
          (W.Game.is_won game_state, W.Game.num_guesses game_state, W.Game.get_board game_state)
        else (
          let guess = W.Solver.make_guess solver_state in
          let new_game_state = W.Game.step game_state guess in
          let feedback =
            match W.Game.last_feedback new_game_state with
            | Some fb -> fb
            | None -> failwith "Unexpected: no feedback after step"
          in
          (* Display bot's guess *)
          Printf.printf "Bot guess %d/%d: %s\n"
            (W.Game.num_guesses new_game_state)
            (W.Game.max_guesses new_game_state)
            (W.Guess.to_string feedback);
          let new_solver_state = W.Solver.update solver_state feedback in
          solver_loop new_game_state new_solver_state
        )
      in
      let solver_won, solver_guesses, solver_board = solver_loop solver_game solver_state in
      Printf.printf "\n";
      
      (* Display comparison *)
      Printf.printf "\n";
      Printf.printf "Human: %s in %d guess%s\n"
        (if human_won then "Won" else "Lost")
        human_guesses
        (if human_guesses = 1 then "" else "es");
      Printf.printf "Bot:   %s in %d guess%s\n"
        (if solver_won then "Won" else "Lost")
        solver_guesses
        (if solver_guesses = 1 then "" else "es");
      
      Printf.printf "\n";
      if human_won && solver_won then (
        if human_guesses < solver_guesses then
          Printf.printf "🏆 You beat the bot! (%d vs %d guesses)\n" human_guesses solver_guesses
        else if human_guesses > solver_guesses then
          Printf.printf "🤖 Bot wins! (%d vs %d guesses)\n" solver_guesses human_guesses
        else
          Printf.printf "🤝 It's a tie! Both solved it in %d guess%s\n" human_guesses (if human_guesses = 1 then "" else "es")
      ) else if human_won && not solver_won then
        Printf.printf "🏆 You won! Bot couldn't solve it.\n"
      else if not human_won && solver_won then
        Printf.printf "🤖 Bot wins! Bot solved it in %d guess%s.\n" solver_guesses (if solver_guesses = 1 then "" else "es")
      else
        Printf.printf "😔 Both lost. The answer was: %s\n" answer
    ) else (
      (* Game still active - check if we can make a guess *)
      if W.Game.can_guess game_state then (
        (* Get guess from user input *)
        Printf.printf "Enter your guess: ";
        Out_channel.flush stdout;
        let user_input = In_channel.input_line In_channel.stdin in
        let guess = match user_input with
          | None -> failwith "Unexpected end of input"
          | Some input -> input
        in
        
        (* Normalize guess for consistency *)
        let normalized_guess = Dict.normalize_word guess in
        
        (* Validate the guess using Utils *)
        match W.Utils.validate_guess normalized_guess with
        | Ok valid_guess ->
          (* Check if word is valid using API *)
          Printf.printf "Validating word via API... ";
          Out_channel.flush stdout;
          if not (Dict.is_valid_word_api valid_guess) then (
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
            
            (* Update solver silently (for competition comparison later) *)
            let new_solver_state = W.Solver.update solver_state feedback in
            
            (* Display current state *)
            Printf.printf "Guess %d/%d: %s\n" 
              (W.Game.num_guesses new_game_state)
              (W.Game.max_guesses new_game_state)
              (W.Guess.to_string feedback);
            
            (* Check if the guess was correct (all green) *)
            if W.Game.is_won new_game_state then (
              Printf.printf "Congratulations! You guessed it in %d time%s!\n" 
                (W.Game.num_guesses new_game_state)
                (if W.Game.num_guesses new_game_state = 1 then "" else "s");
              (* Continue loop to show comparison *)
              loop new_game_state new_solver_state cumulative_hints
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
                  let open Feedback in
                  (fb.guess, fb.colors)
                )
              in
              let updated_hints = Hints.offer_hint ~answer ~guesses_with_colors ~cumulative_hints in
              Printf.printf "\n";
              
              (* Continue loop *)
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
  Printf.printf "Loaded %d valid words\n" (Dict.word_count words_dict);
  Printf.printf "Loaded %d possible answers\n" (Dict.word_count answers_dict);
  Printf.printf "Max guesses: %d\n" max_guesses;
  Printf.printf "Starting game! (Bot will compete after you finish)\n\n";
  
  loop game solver initial_hints

