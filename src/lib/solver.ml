(** Solver module implementation - stub for now *)

module Make (G : Guess.S) = struct
  type t = string list

  let create word_list = word_list
  let make_guess _solver = failwith "Not implemented"
  let update _solver _guess _colors = failwith "Not implemented"
end

