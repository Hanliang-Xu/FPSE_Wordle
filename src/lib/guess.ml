(** Guess module implementation *)

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
        | None -> a_char :: acc)
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
              (counts, Grey :: acc))
    in
    List.rev colors

  let make_feedback guess answer = { guess; colors = generate guess answer }

  let is_correct { colors; _ } = List.for_all colors ~f:(fun c -> match c with Green -> true | _ -> false)

  let color_to_string = function
    | Green -> "G"
    | Yellow -> "Y"
    | Grey -> "."

  let colors_to_string colors =
    List.map colors ~f:color_to_string |> String.concat ~sep:""

  let to_string { guess; colors } =
    Printf.sprintf "%s: %s" guess (colors_to_string colors)
end

