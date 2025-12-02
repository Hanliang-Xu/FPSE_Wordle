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
  let rec loop () =
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
          Printf.printf "invalid input enter y/n\n";
          loop ()
        )
  in
  loop ()

(** Prompt user for feedback granularity *)
let prompt_feedback_granularity () =
  Printf.printf "Feedback mode:\n";
  Printf.printf "  1. Three-state (Green/Yellow/Grey) - standard Wordle\n";
  Printf.printf "  2. Binary (Green/Grey only) - harder mode\n";
  Printf.printf "Choose [default: 1]: ";
  Out_channel.flush stdout;
  match In_channel.input_line In_channel.stdin with
  | None -> Lib.Config.ThreeState
  | Some input ->
      let trimmed = String.strip input in
      if String.is_empty trimmed then Lib.Config.ThreeState
      else if String.equal trimmed "1" then Lib.Config.ThreeState
      else if String.equal trimmed "2" then Lib.Config.Binary
      else (
        Printf.printf "Invalid input. Using default: Three-state\n";
        Lib.Config.ThreeState
      )

(** Prompt user for hint mode selection *)
let prompt_hint_mode () =
  let rec loop () =
    Printf.printf "Hint mode:\n";
    Printf.printf "  1. Show a correct letter in its correct position\n";
    Printf.printf "  2. Show a correct letter (without position)\n";
    Printf.printf "Choose [default: 1]: ";
    Out_channel.flush stdout;
    match In_channel.input_line In_channel.stdin with
    | None -> 1
    | Some input ->
        let trimmed = String.strip input in
        if String.is_empty trimmed then 1
        else if String.equal trimmed "1" then 1
        else if String.equal trimmed "2" then 2
        else (
          Printf.printf "Invalid input. Please enter 1 or 2\n";
          loop ()
        )
  in
  loop ()

(** Generate hint mode 1: correct letter in correct position *)
let generate_hint_mode1 ~answer ~guesses_with_colors =
  let word_length = String.length answer in
  (* Find positions that are not yet revealed as Green *)
  let revealed_positions = 
    List.fold guesses_with_colors ~init:(Set.empty (module Int)) ~f:(fun acc (_, colors) ->
      List.foldi colors ~init:acc ~f:(fun idx acc' color ->
        match color with
        | Lib.Feedback.Green -> Set.add acc' idx
        | _ -> acc'
      )
    )
  in
  (* Find a position that hasn't been revealed yet *)
  let available_positions = 
    List.filter (List.range 0 word_length) ~f:(fun pos ->
      not (Set.mem revealed_positions pos)
    )
  in
  match available_positions with
  | [] -> 
      (* All positions revealed, pick any position *)
      let pos = Random.int word_length in
      (pos, String.get answer pos)
  | positions ->
      let pos = List.nth_exn positions (Random.int (List.length positions)) in
      (pos, String.get answer pos)

(** Generate hint mode 2: correct letter without position *)
let generate_hint_mode2 ~answer ~guesses_with_colors =
  (* Collect all letters that have been revealed as Green or Yellow *)
  let revealed_letters = 
    List.fold guesses_with_colors ~init:(Set.empty (module Char)) ~f:(fun acc (guess, colors) ->
      List.fold2_exn (String.to_list guess) colors ~init:acc ~f:(fun acc' char color ->
        match color with
        | Lib.Feedback.Green | Lib.Feedback.Yellow -> Set.add acc' char
        | _ -> acc'
      )
    )
  in
  (* Find a letter in answer that hasn't been revealed yet *)
  let answer_letters = String.to_list answer |> List.dedup_and_sort ~compare:Char.compare in
  let unrevealed_letters = 
    List.filter answer_letters ~f:(fun c -> not (Set.mem revealed_letters c))
  in
  match unrevealed_letters with
  | [] ->
      (* All letters revealed, pick any letter from answer *)
      let idx = Random.int (String.length answer) in
      String.get answer idx
  | letters ->
      List.nth_exn letters (Random.int (List.length letters))

(** Type for cumulative hints *)
type cumulative_hints = {
  mode1_hints : (int * char) list;  (* (position, letter) pairs *)
  mode2_hints : char list;          (* letters without position *)
}

(** Display all cumulative hints *)
let display_cumulative_hints ~word_length hints =
  if List.is_empty hints.mode1_hints && List.is_empty hints.mode2_hints then
    ()
  else (
    (* Display mode 1 hints (position hints) *)
    if not (List.is_empty hints.mode1_hints) then (
      let hint_display = 
        List.fold hints.mode1_hints ~init:(String.init word_length ~f:(fun _ -> '_'))
          ~f:(fun acc (pos, letter) ->
            String.mapi acc ~f:(fun i current_char ->
              if i = pos then letter else current_char
            )
          )
      in
      Printf.printf "Hint (positions): %s\n" hint_display
    );
    (* Display mode 2 hints (letters without position) *)
    if not (List.is_empty hints.mode2_hints) then (
      let letters_str = 
        List.map hints.mode2_hints ~f:Char.to_string 
        |> String.concat ~sep:", "
      in
      Printf.printf "Hint (letters): %s\n" letters_str
    )
  )

(** Ask user if they want a hint and provide it, updating cumulative hints *)
let offer_hint ~answer ~guesses_with_colors ~cumulative_hints =
  (* Display existing cumulative hints first *)
  let word_length = String.length answer in
  display_cumulative_hints ~word_length cumulative_hints;
  
  let want_hint = prompt_bool ~default:false "Do you want a hint?" in
  if want_hint then (
    let mode = prompt_hint_mode () in
    match mode with
    | 1 ->
        let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
        (* Check if this position is already hinted *)
        let already_hinted = List.exists cumulative_hints.mode1_hints ~f:(fun (p, _) -> p = pos) in
        if already_hinted then (
          Printf.printf "Position %d is already revealed!\n" (pos + 1);
          cumulative_hints
        ) else (
          let new_hint = (pos, letter) in
          let updated_hints = {
            cumulative_hints with
            mode1_hints = cumulative_hints.mode1_hints @ [new_hint]
          } in
          let hint_display = 
            List.fold updated_hints.mode1_hints ~init:(String.init word_length ~f:(fun _ -> '_'))
              ~f:(fun acc (p, l) ->
                String.mapi acc ~f:(fun i current_char ->
                  if i = p then l else current_char
                )
              )
          in
          Printf.printf "Hint: %s\n" hint_display;
          updated_hints
        )
    | 2 ->
        let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
        (* Check if this letter is already hinted *)
        let already_hinted = List.mem cumulative_hints.mode2_hints letter ~equal:Char.equal in
        if already_hinted then (
          Printf.printf "Letter '%c' is already revealed!\n" letter;
          cumulative_hints
        ) else (
          let updated_hints = {
            cumulative_hints with
            mode2_hints = cumulative_hints.mode2_hints @ [letter]
          } in
          let letters_str = 
            List.map updated_hints.mode2_hints ~f:Char.to_string 
            |> String.concat ~sep:", "
          in
          Printf.printf "Hint: The letters %s are in the answer\n" letters_str;
          updated_hints
        )
    | _ -> cumulative_hints
  ) else
    cumulative_hints

(** Get configuration from user input *)
let get_config () =
  Printf.printf "\n=== Wordle Configuration ===\n";
  let word_length = prompt_int ~default:5 ~min:2 ~max:10 "Word length (2-10)" in
  let max_guesses = prompt_int ~default:6 ~min:1 ~max:20 "Max guesses" in
  let show_hints = prompt_bool ~default:true "Show hints (solver's guess)" in
  let feedback_granularity = prompt_feedback_granularity () in
  let show_position_distances = prompt_bool ~default:false "Show position distances for Yellow letters" in
  Printf.printf "\n";
  (word_length, max_guesses, show_hints, feedback_granularity, show_position_distances)

(** Run the game with a given configuration *)
let run_with_config ~word_length ~max_guesses ~show_hints ~feedback_granularity ~show_position_distances =
  let module Config = struct
    let word_length = word_length
    let feedback_granularity = feedback_granularity
    let show_position_distances = show_position_distances
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
  let initial_hints = { mode1_hints = []; mode2_hints = [] } in
  
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
            
            (* Display current state *)
            Printf.printf "Guess %d/%d: %s\n" 
              (W.Game.num_guesses new_game_state)
              (W.Game.max_guesses new_game_state)
              (W.Guess.to_string feedback);
            
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
              let updated_hints = offer_hint ~answer ~guesses_with_colors ~cumulative_hints in
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
  Printf.printf "Max guesses: %d\n" max_guesses;
  Printf.printf "Hints: %s\n" (if show_hints then "enabled" else "disabled");
  Printf.printf "Starting game!\n\n";
  
  loop game solver initial_hints

(** Main entry point *)
let main () =
  (* Initialize random number generator *)
  Random.self_init ();
  
  (* Get configuration from user *)
  let word_length, max_guesses, show_hints, feedback_granularity, show_position_distances = get_config () in
  
  (* Run the game with the configuration *)
  run_with_config ~word_length ~max_guesses ~show_hints ~feedback_granularity ~show_position_distances

let () = main ()

