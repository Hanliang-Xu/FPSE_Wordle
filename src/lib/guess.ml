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
  
  let generate _guess _answer = failwith "Not implemented"
  let make_feedback _guess _answer = failwith "Not implemented"
  let is_correct _feedback = failwith "Not implemented"
  let color_to_string _color = failwith "Not implemented"
  let to_string _feedback = failwith "Not implemented"
  let colors_to_string _colors = failwith "Not implemented"
end

