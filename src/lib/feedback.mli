(** Feedback module for Wordle game *)

module type Config = sig
  val word_length : int
end

module Make (C : Config) : sig
  type color = Green | Yellow | Grey
  type t = color list
  type feedback = {
    guess : string;
    colors : t;
  }
  
  val generate : string -> string -> t
  (** [generate guess answer] returns feedback colors.
      Requires: both strings have length equal to [word_length] *)
  
  val make_feedback : string -> string -> feedback
  (** [make_feedback guess answer] creates a feedback record.
      Requires: both strings have length equal to [word_length] *)
  
  val is_correct : feedback -> bool
  val color_to_string : color -> string
  val to_string : feedback -> string
  val colors_to_string : t -> string
end

