(** User interface module for handling user input and configuration *)

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
  | None -> Config.ThreeState
  | Some input ->
      let trimmed = String.strip input in
      if String.is_empty trimmed then Config.ThreeState
      else if String.equal trimmed "1" then Config.ThreeState
      else if String.equal trimmed "2" then Config.Binary
      else (
        Printf.printf "Invalid input. Using default: Three-state\n";
        Config.ThreeState
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

(** Get configuration from user input *)
let get_config () =
  Printf.printf "\n=== Wordle Configuration ===\n";
  let word_length = prompt_int ~default:5 ~min:2 ~max:10 "Word length (2-10)" in
  let max_guesses = prompt_int ~default:6 ~min:1 ~max:20 "Max guesses" in
  (* show_hints is kept for backward compatibility but no longer used (solver runs as competition) *)
  let show_hints = false in
  let feedback_granularity = prompt_feedback_granularity () in
  let show_position_distances = prompt_bool ~default:false "Show position distances for Yellow letters" in
  Printf.printf "\n";
  (word_length, max_guesses, show_hints, feedback_granularity, show_position_distances)

