(** Guess module for Wordle game - provides feedback generation functionality *)

(** Module type for Guess modules *)
module type S = sig
  include module type of Feedback
  
  val generate : string -> string -> Feedback.t
  (** [generate guess answer] returns feedback colors.
      Requires: both strings have length equal to [word_length] *)
  
  val make_feedback : string -> string -> Feedback.feedback
  (** [make_feedback guess answer] creates a feedback record.
      Requires: both strings have length equal to [word_length] *)
  
  val is_correct : Feedback.feedback -> bool
  val color_to_string : Feedback.color -> string
  val to_string : Feedback.feedback -> string
  val colors_to_string : Feedback.t -> string
end

open Config

module Make (C : Config) : S

