(** Solver module for Wordle game *)

module Make (G : Guess.S) : sig
  type t
  (** The type representing a solver state *)

  val create : string list -> t
  (** [create word_list] creates a new solver initialized with the given word list *)

  val make_guess : t -> string
  (** [make_guess solver] returns the next guess to make based on the current solver state *)

  val update : t -> G.feedback -> t
  (** [update solver fb] updates the solver state with the feedback from a guess.
      [fb.guess] is the word that was guessed, and [fb.colors] is the feedback for each letter. *)
end

