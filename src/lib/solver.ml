(** Solver module implementation - stub for now *)

module type Feedback = sig
  type color = Green | Yellow | Grey
end

module Make (F : Feedback) = struct
  type t = string list

  let create word_list = word_list
  let make_guess _solver = failwith "Not implemented"
  let update _solver _guess _colors = failwith "Not implemented"
end

