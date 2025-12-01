(** Game module implementation *)

module Make (G : Guess.S) = struct
  type t = {
    board : G.feedback list;
    max_guesses : int;
    answer : string;
  }

  (** Initialize an empty game state with the answer *)
  let init ~answer ~max_guesses = {
    board = [];
    max_guesses;
    answer;
  }

  (** Add a new guess to the game state, generating feedback internally *)
  let step game_state guess =
    let feedback = G.make_feedback guess game_state.answer in
    { game_state with board = game_state.board @ [feedback] }

  (** Return the number of guesses made so far *)
  let num_guesses game_state = List.length game_state.board

  (** Check if the last guess was correct (all colors are Green) *)
  let is_won game_state =
    match List.rev game_state.board with
    | [] -> false
    | feedback :: _ -> G.is_correct feedback

  (** Return the current board state *)
  let get_board game_state = game_state.board

  (** Return the most recent feedback, or None if no guesses have been made *)
  let last_feedback game_state =
    match List.rev game_state.board with
    | [] -> None
    | feedback :: _ -> Some feedback

  (** Return the number of guesses remaining *)
  let remaining_guesses game_state =
    max 0 (game_state.max_guesses - num_guesses game_state)

  (** Return the maximum number of guesses allowed *)
  let max_guesses game_state = game_state.max_guesses

  (** Check if the game is over (won or max guesses reached) *)
  let is_over game_state =
    is_won game_state || num_guesses game_state >= game_state.max_guesses

  (** Check if more guesses can be made *)
  let can_guess game_state =
    not (is_over game_state)
end

