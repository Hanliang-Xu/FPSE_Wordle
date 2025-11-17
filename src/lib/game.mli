(** Game module for Wordle game *)

module Make (G : Guess.S) : sig
  type t = {
    board : G.feedback list;
    max_guesses : int;
  }
  (** The game state, containing the board (a list of rows, each with a guess and its feedback colors)
      and the maximum number of guesses allowed *)
  
  val init : max_guesses:int -> t
  (** [init ~max_guesses] returns an empty game state with no guesses made
      and the specified maximum number of guesses allowed *)
  
  val step : t -> string -> t
  (** [step game_state guess] adds a new guess to the game state.
      Requires: [guess] has length equal to [word_length] *)
  
  val num_guesses : t -> int
  (** [num_guesses game_state] returns the number of guesses made so far *)
  
  val is_won : t -> bool
  (** [is_won game_state] returns true if the last guess was correct
      (i.e., all colors in the last feedback are Green) *)
  
  val get_board : t -> G.feedback list
  (** [get_board game_state] returns the current board state,
      a list of all guesses made so far with their feedback *)
  
  val last_feedback : t -> G.feedback option
  (** [last_feedback game_state] returns the most recent guess and its feedback,
      or [None] if no guesses have been made yet *)
  
  val remaining_guesses : t -> int
  (** [remaining_guesses game_state] returns the number of guesses remaining
      (max_guesses - num_guesses) *)
  
  val max_guesses : t -> int
  (** [max_guesses game_state] returns the maximum number of guesses allowed for this game *)
  
  val is_over : t -> bool
  (** [is_over game_state] returns true if the game is over,
      either because it was won or the maximum number of guesses has been reached *)
  
  val can_guess : t -> bool
  (** [can_guess game_state] returns true if more guesses can be made
      (i.e., the game is not won and not at max guesses) *)
end

