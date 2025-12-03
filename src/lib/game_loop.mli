(** Game loop module for running the Wordle game *)

(** Run the game with a given configuration *)
val run_with_config :
  word_length:int ->
  max_guesses:int ->
  show_hints:bool ->
  feedback_granularity:Config.feedback_granularity ->
  show_position_distances:bool ->
  unit

