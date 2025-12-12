(** Solver module implementation - frequency-based strategy *)

open Core
open Config

module Make (C : Config) (G : Guess.S) = struct
  (* Solver state: tracks remaining candidates and guess history *)
  type t = {
    candidates : string list;
    history : G.feedback list;
  }

  let create word_list =
    { candidates = word_list; history = [] }

  (* Calculate letter frequencies from remaining candidates *)
  let calculate_frequencies candidates =
    let freq_map = Map.empty (module Char) in
    List.fold candidates ~init:freq_map ~f:(fun acc word ->
      String.fold word ~init:acc ~f:(fun acc char ->
        Map.update acc char ~f:(function
          | None -> 1
          | Some count -> count + 1)))

  (* Score a word based on letter frequencies *)
  let score_word frequencies word =
    (* Use fold to accumulate score and seen characters immutably *)
    let seen_chars = Set.empty (module Char) in
    let score, _ = String.fold word ~init:(0, seen_chars) ~f:(fun (acc_score, acc_seen) char ->
      (* Prefer unique letters: only count each letter once *)
      if Set.mem acc_seen char then
        (acc_score, acc_seen)  (* Already seen, don't add to score *)
      else (
        let freq = Map.find frequencies char |> Option.value ~default:0 in
        let new_score = acc_score + freq in
        let new_seen = Set.add acc_seen char in
        (new_score, new_seen)
      )
    ) in
    score

  (* Check if a word is consistent with feedback *)
  let is_consistent_with_feedback word (feedback : G.feedback) =
    let guess = feedback.guess in
    let colors = feedback.colors in
    let distances = feedback.distances in
    let word_chars = String.to_list word in
    let guess_chars = String.to_list guess in
    let word_length = List.length word_chars in
    
    (* First pass: check Green positions (exact matches) *)
    let green_positions = List.mapi colors ~f:(fun i color ->
      match color with
      | G.Green -> Some i
      | _ -> None)
    |> List.filter_map ~f:Fn.id in
    
    (* Verify all Green positions match *)
    let green_matches = List.for_all green_positions ~f:(fun pos ->
      Char.equal (List.nth_exn word_chars pos) (List.nth_exn guess_chars pos)) in
    
    if not green_matches then false
    else
      (* Check distance hints if available *)
      (* Distance hints tell us the exact position for Yellow letters *)
      let distance_hints_valid = match distances with
      | None -> true  (* No distance hints, skip this check *)
      | Some dist_list ->
          List.for_alli dist_list ~f:(fun guess_pos dist_opt ->
            match dist_opt with
            | None -> true  (* No distance hint for this position *)
            | Some distance ->
                (* This position has a distance hint - check if it's Yellow *)
                (match List.nth colors guess_pos with
                | Some G.Yellow ->
                    (* Calculate target position: guess_pos + distance *)
                    let target_pos = guess_pos + distance in
                    (* Check bounds *)
                    if target_pos < 0 || target_pos >= word_length then false
                    else
                      (* Check that the letter appears at the target position *)
                      let guess_char = List.nth_exn guess_chars guess_pos in
                      let target_char = List.nth_exn word_chars target_pos in
                      Char.equal guess_char target_char
                | _ -> true))  (* Distance hints only apply to Yellow letters *)
      in
      
      if not distance_hints_valid then false
      else
        (* Second pass: check Yellow and Grey constraints *)
        (* Count letters in word (excluding Green positions) *)
        let word_letter_counts =
          List.mapi word_chars ~f:(fun i char ->
            if List.mem green_positions i ~equal:Int.equal then None
            else Some char)
          |> List.filter_map ~f:Fn.id
          |> List.fold ~init:(Map.empty (module Char)) ~f:(fun acc char ->
              Map.update acc char ~f:(function
                | None -> 1
                | Some count -> count + 1))
        in
        
        (* Check each position, accumulating consumed letters immutably *)
        let init_state = (true, Map.empty (module Char)) in
        let result, _ = List.foldi colors ~init:init_state ~f:(fun i (acc_valid, consumed_counts) color ->
          if not acc_valid then (false, consumed_counts)
          else
            let guess_char = List.nth_exn guess_chars i in
            let word_char = List.nth_exn word_chars i in
            match color with
            | G.Green ->
                (* Already checked in first pass *)
                (acc_valid, consumed_counts)
            | G.Yellow ->
                (* Letter must be in word but NOT at this position *)
                if Char.equal guess_char word_char then (false, consumed_counts)
                else
                  (* If distance hint exists, we already checked exact position above *)
                  (* Otherwise, check if letter is available (not already consumed by other Yellow matches) *)
                  let available_in_word = Map.find word_letter_counts guess_char |> Option.value ~default:0 in
                  let already_consumed = Map.find consumed_counts guess_char |> Option.value ~default:0 in
                  if available_in_word > already_consumed then (
                    (* Consume one occurrence of this letter *)
                    let updated_consumed = Map.update consumed_counts guess_char ~f:(function
                      | None -> 1
                      | Some c -> c + 1) in
                    (true, updated_consumed)
                  ) else (false, consumed_counts)
            | G.Grey ->
                match C.feedback_granularity with
                | Config.Binary ->
                    (* Binary Mode: Grey means letter is NOT at this position *)
                    (* It does NOT imply the letter is absent from the word *)
                    if Char.equal guess_char word_char then (false, consumed_counts)
                    else (acc_valid, consumed_counts)
                | Config.ThreeState ->
                    (* Standard Mode: Letter must NOT be in word (unless already marked Yellow/Green elsewhere) *)
                    (* Check if this letter appears elsewhere as Yellow or Green *)
                    let appears_elsewhere = List.existsi colors ~f:(fun j c ->
                      j <> i && Char.equal (List.nth_exn guess_chars j) guess_char &&
                      match c with
                      | G.Green | G.Yellow -> true
                      | G.Grey -> false) in
                    if appears_elsewhere then (acc_valid, consumed_counts)
                    else
                      (* Letter should not appear in word at all (excluding Green positions) *)
                      let count = Map.find word_letter_counts guess_char |> Option.value ~default:0 in
                      (count = 0, consumed_counts))
        in
        result

  (* Filter candidates based on all feedback history *)
  let filter_candidates candidates history =
    List.fold history ~init:candidates ~f:(fun acc feedback ->
      List.filter acc ~f:(fun word -> is_consistent_with_feedback word feedback))

  let make_guess solver =
    match solver.candidates with
    | [] -> raise (Invalid_argument "No candidates remaining")
    | [single] -> single  (* Only one candidate left *)
    | candidates ->
        (* Calculate letter frequencies from remaining candidates *)
        let frequencies = calculate_frequencies candidates in
        
        (* Score all candidates and find the best *)
        let scored = List.map candidates ~f:(fun word ->
          (word, score_word frequencies word)) in
        
        (* Sort by score (descending) and return the highest *)
        let sorted = List.sort scored ~compare:(fun (_, s1) (_, s2) -> Int.compare s2 s1) in
        match sorted with
        | [] -> raise (Invalid_argument "No candidates after scoring")
        | (best_word, _) :: _ -> best_word

  let update solver feedback =
    (* Filter candidates based on new feedback *)
    let updated_history = feedback :: solver.history in
    let filtered_candidates = filter_candidates solver.candidates updated_history in
    { candidates = filtered_candidates; history = updated_history }

  let candidate_count solver =
    List.length solver.candidates

  let get_candidates solver =
    solver.candidates
end

