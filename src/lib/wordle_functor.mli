(** Configuration module type for Wordle functor *)
module type Config = sig
  val word_length : int
end

(** Functor that creates a Wordle game module for a specific word length.
    This functor composes the Feedback, Game, Utils, and Solver modules.
    The implementation is in wordle.ml, which instantiates the functors from
    feedback.mli, game.mli, utils.mli, and solver.mli. *)
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
    val make_feedback : string -> string -> feedback
    val is_correct : feedback -> bool
    val color_to_string : color -> string
    val to_string : feedback -> string
    val colors_to_string : t -> string
  end

  module Game : sig
    type t = {
      board : Feedback.feedback list;
      max_guesses : int;
    }
    
    val init : max_guesses:int -> t
    val step : t -> string -> t
    val num_guesses : t -> int
    val is_won : t -> bool
    val get_board : t -> Feedback.feedback list
    val last_feedback : t -> Feedback.feedback option
    val remaining_guesses : t -> int
    val max_guesses : t -> int
    val is_over : t -> bool
    val can_guess : t -> bool
  end

  module Utils : sig
    val validate_length : string -> bool
    val validate_guess : string -> (string, string) result
  end

  module Solver : sig
    type t
    val create : string list -> t
    val make_guess : t -> string
    val update : t -> string -> Feedback.color list -> t
  end
end

