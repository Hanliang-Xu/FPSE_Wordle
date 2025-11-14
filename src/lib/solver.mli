(** Solver module for Wordle game *)

module type Feedback = sig
  type color = Green | Yellow | Grey
end

module Make (F : Feedback) : sig
  type t
  (** The type representing a solver state *)

  val create : string list -> t
  (** [create word_list] creates a new solver initialized with the given word list *)

  val make_guess : t -> string
  (** [make_guess solver] returns the next guess to make based on the current solver state *)

  val update : t -> string -> F.color list -> t
  (** [update solver guess colors] updates the solver state with the feedback from a guess.
      [guess] is the word that was guessed, and [colors] is the feedback for each letter. *)
end

