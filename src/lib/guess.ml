(** Guess module implementation *)

open Core
open Config

module type S = sig
  include module type of Feedback
  
  val generate : string -> string -> Feedback.t
  val make_feedback : string -> string -> Feedback.feedback
  val is_correct : Feedback.feedback -> bool
  val color_to_string : Feedback.color -> string
  val to_string : Feedback.feedback -> string
  val colors_to_string : Feedback.t -> string
end

module Make (C : Config) : S = struct
  include Feedback
  
  let generate guess answer =
    match C.feedback_granularity with
    | Config.Binary ->
        (* Binary mode: simple position-by-position check *)
        let guess_chars = String.to_list guess in
        let answer_chars = String.to_list answer in
        List.map2_exn guess_chars answer_chars ~f:(fun g a ->
          if Char.equal g a then Green else Grey)
    | Config.ThreeState ->
        (* Three-state mode: standard Wordle algorithm with Green/Yellow/Grey *)
        let guess_chars = String.to_list guess in
        let answer_chars = String.to_list answer in
        (* First pass: mark exact matches as Green *)
        let exact_matches =
          List.map2_exn guess_chars answer_chars ~f:(fun g a ->
            if Char.equal g a then Some Green else None)
        in
        (* Count remaining letters in answer (excluding exact matches) *)
        let remaining_counts =
          List.fold2_exn answer_chars exact_matches ~init:[] ~f:(fun acc a_char match_opt ->
            match match_opt with
            | Some Green -> acc
            | None -> a_char :: acc
            | Some _ -> a_char :: acc)  (* Unreachable: exact_matches only has Some Green or None *)
          |> List.fold ~init:(Map.empty (module Char)) ~f:(fun acc c ->
            Map.update acc c ~f:(function
              | None -> 1
              | Some count -> count + 1))
        in
        (* Second pass: determine Yellow vs Grey for non-exact matches *)
        let _, colors =
          List.fold2_exn guess_chars exact_matches ~init:(remaining_counts, [])
            ~f:(fun (counts, acc) g_char match_opt ->
              match match_opt with
              | Some Green -> (counts, Green :: acc)
              | None ->
                let count = Map.find counts g_char |> Option.value ~default:0 in
                if count > 0 then
                  let new_counts = Map.set counts ~key:g_char ~data:(count - 1) in
                  (new_counts, Yellow :: acc)
                else
                  (counts, Grey :: acc)
              | Some _ ->
                (* Unreachable: exact_matches only has Some Green or None *)
                let count = Map.find counts g_char |> Option.value ~default:0 in
                if count > 0 then
                  let new_counts = Map.set counts ~key:g_char ~data:(count - 1) in
                  (new_counts, Yellow :: acc)
                else
                  (counts, Grey :: acc))
        in
        List.rev colors

  (* Calculate distances for Yellow letters *)
  let calculate_distances guess answer colors =
    if not C.show_position_distances then None
    else
      let guess_chars = String.to_list guess in
      let answer_chars = String.to_list answer in
      (* Build a map of answer positions available for each letter (excluding Green matches) *)
      let available_positions =
        List.mapi answer_chars ~f:(fun i a_char ->
          let color = List.nth_exn colors i in
          match color with
          | Green -> None  (* Position already matched *)
          | _ -> Some (i, a_char))
        |> List.filter_map ~f:Fn.id
        |> List.fold ~init:(Map.empty (module Char)) ~f:(fun acc (pos, char) ->
            Map.update acc char ~f:(function
              | None -> [pos]
              | Some positions -> pos :: positions))
      in
      (* Calculate distance for each position, tracking used positions *)
      let _, distances = List.foldi guess_chars ~init:(available_positions, []) ~f:(fun guess_pos (avail, acc) g_char ->
        let color = List.nth_exn colors guess_pos in
        match color with
        | Green -> (avail, None :: acc)  (* Already correct, no distance *)
        | Grey -> (avail, None :: acc)   (* Not in word, no distance *)
        | Yellow ->
            (* Find the nearest available position for this letter in the answer *)
            (match Map.find avail g_char with
            | Some positions ->
                (* Find the closest position to guess_pos *)
                (match List.min_elt positions ~compare:(fun p1 p2 ->
                  let dist1 = abs (p1 - guess_pos) in
                  let dist2 = abs (p2 - guess_pos) in
                  Int.compare dist1 dist2) with
                | Some answer_pos ->
                    let distance = answer_pos - guess_pos in
                    (* Remove this position from available for future matches *)
                    let updated_positions = List.filter positions ~f:(fun p -> p <> answer_pos) in
                    let updated_avail = if List.is_empty updated_positions then
                        Map.remove avail g_char
                      else
                        Map.set avail ~key:g_char ~data:updated_positions
                    in
                    (updated_avail, Some distance :: acc)
                | None -> (avail, None :: acc))
            | None -> (avail, None :: acc)))
      in
      Some (List.rev distances)

  let make_feedback guess answer =
    let colors = generate guess answer in
    let distances = calculate_distances guess answer colors in
    { guess; colors; distances }

  let is_correct { colors; _ } =
    List.for_all colors ~f:(function Green -> true | _ -> false)

  let color_to_string = function
    | Green -> "G"
    | Yellow -> "Y"
    | Grey -> "."

  let colors_to_string colors =
    List.map colors ~f:color_to_string |> String.concat ~sep:""

  let to_string { guess; colors; distances } =
    let base = Printf.sprintf "%s: %s" guess (colors_to_string colors) in
    match distances with
    | None -> base
    | Some dist_list ->
        (* Build distance string showing distance for each Yellow letter position *)
        let dist_str = List.mapi colors ~f:(fun i color ->
          match (color, List.nth_exn dist_list i) with
          | Yellow, Some d when d > 0 -> Printf.sprintf "pos%d:+%d" i d
          | Yellow, Some d when d < 0 -> Printf.sprintf "pos%d:%d" i d
          | Yellow, Some 0 -> Printf.sprintf "pos%d:0" i
          | _ -> ""
        )
        |> List.filter ~f:(fun s -> not (String.is_empty s))
        |> String.concat ~sep:", "
        in
        if String.is_empty dist_str then base
        else Printf.sprintf "%s [%s]" base dist_str
end

