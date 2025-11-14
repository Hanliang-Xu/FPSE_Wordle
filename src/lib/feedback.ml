(** Feedback module implementation - stub for now *)

module type Config = sig
  val word_length : int
end

module Make (C : Config) = struct
  type color = Green | Yellow | Grey
  type t = color list
  type feedback = {
    guess : string;
    colors : t;
  }

  let generate _guess _answer = failwith "Not implemented"
  let make_feedback _guess _answer = failwith "Not implemented"
  let is_correct _feedback = failwith "Not implemented"
  let color_to_string _color = failwith "Not implemented"
  let to_string _feedback = failwith "Not implemented"
  let colors_to_string _colors = failwith "Not implemented"
end

