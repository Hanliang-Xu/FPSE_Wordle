(** Functor that creates a Wordle game module for a specific word length.
    This functor composes the Feedback, Game, Utils, and Solver modules.
    The implementation is in wordle.ml, which instantiates the functors from
    feedback.mli, game.mli, utils.mli, and solver.mli. *)
module Make (C : Config.Config) : sig
  open Feedback
  
  val word_length : int
  (** The configured word length for this Wordle instance *)

  module Guess : Guess.S
  (** The Guess module for generating feedback *)

  module Game : sig
    type t = {
      board : feedback list;
      max_guesses : int;
      answer : string;
    }
    
    val init : answer:string -> max_guesses:int -> t
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
    (** Opaque solver state that tracks remaining candidates and guess history. *)

    val create : string list -> t
    (** [create words] initializes the solver with an initial set of candidate words. *)

    val make_guess : t -> string
    (** [make_guess solver] selects the next guess word based on the current solver state. *)

    val update : t -> Feedback.feedback -> t
    (** [update solver fb] updates the solver state with the full feedback record for a guess. *)

    val candidate_count : t -> int
    (** [candidate_count solver] returns the number of remaining candidate words. *)

    val get_candidates : t -> string list
    (** [get_candidates solver] returns the current list of remaining candidate words.
        Useful for debugging. *)
  end
end

