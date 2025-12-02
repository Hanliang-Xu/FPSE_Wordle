(** Solver module for Wordle game - uses frequency-based strategy *)

module Make (G : Guess.S) : sig
  type t
  (** The type representing a solver state.
      Tracks remaining candidate words and guess history. *)

  val create : string list -> t
  (** [create word_list] creates a new solver initialized with the given word list.
      The word list should contain all possible candidate words (typically from words.txt).
      The solver will filter these based on feedback using a frequency-based strategy. *)

  val make_guess : t -> string
  (** [make_guess solver] returns the next guess to make based on the current solver state.
      
      Strategy: Frequency-based approach
      - Calculates letter frequencies from remaining candidates
      - Scores words based on how many high-frequency letters they contain
      - Prefers words with unique letter positions (no duplicate letters in guess)
      - Returns the highest-scoring word from remaining candidates
      
      Raises [Invalid_argument] if no candidates remain. *)

  val update : t -> G.feedback -> t
  (** [update solver fb] updates the solver state with the feedback from a guess.
      Filters remaining candidates to only include words consistent with all feedback.
      
      Filtering rules:
      - Green: letter must be at exact position
      - Yellow: letter must be in word but NOT at that position
      - Grey: letter must NOT be in word (unless already marked Yellow/Green elsewhere)
      
      [fb.guess] is the word that was guessed, and [fb.colors] is the feedback for each letter. *)

  val candidate_count : t -> int
  (** [candidate_count solver] returns the number of remaining candidate words.
      Useful for debugging or displaying solver progress. *)

  val get_candidates : t -> string list
  (** [get_candidates solver] returns the current list of remaining candidate words.
      Useful for debugging or displaying solver state.
      Note: This may be a large list, use with caution. *)
end

