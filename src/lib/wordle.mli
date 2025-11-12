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
    type t = {
      board : Feedback.feedback list;
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
    
    val get_board : t -> Feedback.feedback list
    (** [get_board game_state] returns the current board state,
        a list of all guesses made so far with their feedback *)
    
    val last_feedback : t -> Feedback.feedback option
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

  module Utils : sig
    val validate_length : string -> bool
    (** [validate_length s] returns true if [s] has the correct word length *)
    
    val validate_guess : string -> (string, string) result
    (** [validate_guess s] returns [Ok s] if valid, [Error msg] if invalid length *)
  end
end

