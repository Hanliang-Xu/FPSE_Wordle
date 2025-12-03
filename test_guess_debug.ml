open Core

module Config5 = struct
  let word_length = 5
  let feedback_granularity = Lib.Config.ThreeState
  let show_position_distances = false
end

module Guess5 = Lib.Guess.Make (Config5)

let color_to_char = function
  | Guess5.Green -> 'G'
  | Guess5.Yellow -> 'Y'
  | Guess5.Grey -> '.'

let test_case name guess answer =
  let colors = Guess5.generate guess answer in
  let result = String.of_char_list (List.map colors ~f:color_to_char) in
  Printf.printf "%s: %s vs %s = %s\n" name guess answer result

let () =
  test_case "partial_matches" "HELLO" "WORLD";
  test_case "yellow_letters" "WORLD" "BELOW";
  test_case "duplicate_guess_single_answer" "SPEED" "ABIDE";
  test_case "duplicate_one_green" "FLOOR" "ROBOT";
  test_case "duplicate_both_yellow" "REELS" "LEVER";
  test_case "complex_duplicates" "LLAMA" "LABEL";
  test_case "answer_has_more_duplicates" "BELLE" "LABEL";
  test_case "mixed_feedback" "CRANE" "TRACE";
  test_case "6letter" "PURPLE" "ORANGE";
  test_case "6letter_duplicates" "BANANA" "ANANAS";
  test_case "binary_partial" "HELLO" "WORLD";
  test_case "binary_single" "HELLO" "WORLD"

