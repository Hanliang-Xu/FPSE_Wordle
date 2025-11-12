(** Configuration module type for Wordle functor *)
module type Config = sig
  val word_length : int
end

(** Functor that creates a Wordle game module for a specific word length *)
[@@@ocaml.warning "-67"]
module Make (C : Config) : sig
  val word_length : int
  (** The configured word length for this Wordle instance *)

  module Feedback : sig
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

  module Game : sig
    type t = Feedback.t list
    val step : t -> string -> t
    (** [step game_state guess] adds a new guess to the game state.
        Requires: [guess] has length equal to [word_length] *)
  end

  module Utils : sig
    val validate_length : string -> bool
    (** [validate_length s] returns true if [s] has the correct word length *)
    
    val validate_guess : string -> (string, string) result
    (** [validate_guess s] returns [Ok s] if valid, [Error msg] if invalid length *)
  end
end

