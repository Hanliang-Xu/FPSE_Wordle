(** Game module implementation - stub for now *)

module type Config = sig
  val word_length : int
end

module type Feedback = sig
  type color = Green | Yellow | Grey
  type t = color list
  type feedback = {
    guess : string;
    colors : t;
  }
end

module Make (C : Config) (F : Feedback) = struct
  type t = {
    board : F.feedback list;
    max_guesses : int;
  }

  let init ~max_guesses = failwith "Not implemented"
  let step _game_state _guess = failwith "Not implemented"
  let num_guesses _game_state = failwith "Not implemented"
  let is_won _game_state = failwith "Not implemented"
  let get_board _game_state = failwith "Not implemented"
  let last_feedback _game_state = failwith "Not implemented"
  let remaining_guesses _game_state = failwith "Not implemented"
  let max_guesses _game_state = failwith "Not implemented"
  let is_over _game_state = failwith "Not implemented"
  let can_guess _game_state = failwith "Not implemented"
end

