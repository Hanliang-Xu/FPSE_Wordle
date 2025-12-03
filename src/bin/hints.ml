(** Hints module for generating and displaying game hints *)

open Core

(** Type for cumulative hints *)
type cumulative_hints = {
  mode1_hints : (int * char) list;  (* (position, letter) pairs *)
  mode2_hints : char list;          (* letters without position *)
}

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
  
  let want_hint = Ui.prompt_bool ~default:false "Do you want a hint?" in
  if want_hint then (
    let mode = Ui.prompt_hint_mode () in
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

