(** Solver module implementation - dummy solver for testing *)

module Make (G : Guess.S) = struct
  (* Dummy solver state: just stores a fixed word to always guess *)
  type t = {
    fixed_guess : string;
  }

  let create word_list =
    (* Pick the first word from the list, or use a default if empty *)
    let fixed_guess =
      match word_list with
      | [] -> "CRANE"  (* Fallback default word *)
      | first :: _ -> first
    in
    { fixed_guess }

  let make_guess solver =
    solver.fixed_guess

  let update solver _feedback =
    (* Dummy solver ignores feedback and always guesses the same word *)
    solver
end

