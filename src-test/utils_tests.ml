(** Comprehensive test suite for Guess validation helpers *)

open Core
open OUnit2

(** Test Guess validation helpers with different configurations *)

module Config3 = struct
  let word_length = 3
  let feedback_granularity = Lib.Config.ThreeState
  let show_position_distances = false
end

module Config5 = struct
  let word_length = 5
  let feedback_granularity = Lib.Config.ThreeState
  let show_position_distances = false
end

module Config7 = struct
  let word_length = 7
  let feedback_granularity = Lib.Config.Binary
  let show_position_distances = false
end

module Guess3 = Lib.Guess.Make (Config3)
module Guess5 = Lib.Guess.Make (Config5)
module Guess7 = Lib.Guess.Make (Config7)

(** Test validate_length *)
let test_validate_length_3letter_correct _ =
  assert_bool "3-letter word should be valid" (Guess3.validate_length "cat");
  assert_bool "3-letter word should be valid" (Guess3.validate_length "dog");
  assert_bool "3-letter word should be valid" (Guess3.validate_length "xyz")

let test_validate_length_3letter_incorrect _ =
  assert_bool "2-letter word should be invalid" (not (Guess3.validate_length "ab"));
  assert_bool "4-letter word should be invalid" (not (Guess3.validate_length "abcd"));
  assert_bool "5-letter word should be invalid" (not (Guess3.validate_length "abcde"));
  assert_bool "Empty string should be invalid" (not (Guess3.validate_length ""));
  assert_bool "1-letter word should be invalid" (not (Guess3.validate_length "a"))

let test_validate_length_5letter_correct _ =
  assert_bool "5-letter word should be valid" (Guess5.validate_length "hello");
  assert_bool "5-letter word should be valid" (Guess5.validate_length "world");
  assert_bool "5-letter word should be valid" (Guess5.validate_length "CRANE")

let test_validate_length_5letter_incorrect _ =
  assert_bool "3-letter word should be invalid" (not (Guess5.validate_length "cat"));
  assert_bool "4-letter word should be invalid" (not (Guess5.validate_length "word"));
  assert_bool "6-letter word should be invalid" (not (Guess5.validate_length "python"));
  assert_bool "Empty string should be invalid" (not (Guess5.validate_length ""))

let test_validate_length_7letter_correct _ =
  assert_bool "7-letter word should be valid" (Guess7.validate_length "example");
  assert_bool "7-letter word should be valid" (Guess7.validate_length "testing")

let test_validate_length_7letter_incorrect _ =
  assert_bool "5-letter word should be invalid" (not (Guess7.validate_length "hello"));
  assert_bool "8-letter word should be invalid" (not (Guess7.validate_length "computer"))

(** Test validate_guess *)
let test_validate_guess_3letter_success _ =
  match Guess3.validate_guess "cat" with
  | Ok word -> assert_equal "cat" word ~printer:Fn.id
  | Error _ -> assert_failure "Should return Ok for valid 3-letter word"

let test_validate_guess_3letter_failure _ =
  match Guess3.validate_guess "abcd" with
  | Ok _ -> assert_failure "Should return Error for invalid length"
  | Error msg -> 
      assert_bool "Error message should contain expected length" 
        (String.is_substring msg ~substring:"expected 3");
      assert_bool "Error message should contain actual length" 
        (String.is_substring msg ~substring:"got 4")

let test_validate_guess_5letter_success _ =
  match Guess5.validate_guess "hello" with
  | Ok word -> assert_equal "hello" word ~printer:Fn.id
  | Error _ -> assert_failure "Should return Ok for valid 5-letter word"

let test_validate_guess_5letter_failure _ =
  match Guess5.validate_guess "hi" with
  | Ok _ -> assert_failure "Should return Error for invalid length"
  | Error msg -> 
      assert_bool "Error message should contain expected length" 
        (String.is_substring msg ~substring:"expected 5");
      assert_bool "Error message should contain actual length" 
        (String.is_substring msg ~substring:"got 2")

let test_validate_guess_empty_string _ =
  match Guess5.validate_guess "" with
  | Ok _ -> assert_failure "Should return Error for empty string"
  | Error msg -> 
      assert_bool "Error message should contain expected length" 
        (String.is_substring msg ~substring:"expected 5");
      assert_bool "Error message should contain actual length" 
        (String.is_substring msg ~substring:"got 0")

let test_validate_guess_too_long _ =
  match Guess5.validate_guess "python" with
  | Ok _ -> assert_failure "Should return Error for too long word"
  | Error msg -> 
      assert_bool "Error message should contain expected length" 
        (String.is_substring msg ~substring:"expected 5");
      assert_bool "Error message should contain actual length" 
        (String.is_substring msg ~substring:"got 6")

let test_validate_guess_case_insensitive _ =
  (* validate_length should work regardless of case *)
  assert_bool "Uppercase should be valid" (Guess5.validate_length "HELLO");
  assert_bool "Mixed case should be valid" (Guess5.validate_length "HeLlO");
  assert_bool "Lowercase should be valid" (Guess5.validate_length "hello")

let test_validate_guess_multiple_configs _ =
  (* Test that different configurations work independently *)
  assert_bool "3-letter config validates 3-letter words" (Guess3.validate_length "abc");
  assert_bool "3-letter config rejects 5-letter words" (not (Guess3.validate_length "abcde"));
  assert_bool "5-letter config validates 5-letter words" (Guess5.validate_length "abcde");
  assert_bool "5-letter config rejects 3-letter words" (not (Guess5.validate_length "abc"));
  assert_bool "7-letter config validates 7-letter words" (Guess7.validate_length "abcdefg");
  assert_bool "7-letter config rejects 5-letter words" (not (Guess7.validate_length "abcde"))

let test_validate_guess_edge_cases _ =
  (* Test edge cases *)
  let single_char = String.make 5 'a' in
  assert_bool "5 identical characters should be valid" (Guess5.validate_length single_char);
  
  let special_chars = "a-b-c" in
  assert_bool "Special characters should be valid if length matches" 
    (Guess5.validate_length special_chars);
  
  match Guess5.validate_guess special_chars with
  | Ok word -> assert_equal "a-b-c" word ~printer:Fn.id
  | Error _ -> assert_failure "Special characters should be accepted if length is correct"

let suite =
  "Guess validation tests" >::: [
    "validate_length_3letter_correct" >:: test_validate_length_3letter_correct;
    "validate_length_3letter_incorrect" >:: test_validate_length_3letter_incorrect;
    "validate_length_5letter_correct" >:: test_validate_length_5letter_correct;
    "validate_length_5letter_incorrect" >:: test_validate_length_5letter_incorrect;
    "validate_length_7letter_correct" >:: test_validate_length_7letter_correct;
    "validate_length_7letter_incorrect" >:: test_validate_length_7letter_incorrect;
    "validate_guess_3letter_success" >:: test_validate_guess_3letter_success;
    "validate_guess_3letter_failure" >:: test_validate_guess_3letter_failure;
    "validate_guess_5letter_success" >:: test_validate_guess_5letter_success;
    "validate_guess_5letter_failure" >:: test_validate_guess_5letter_failure;
    "validate_guess_empty_string" >:: test_validate_guess_empty_string;
    "validate_guess_too_long" >:: test_validate_guess_too_long;
    "validate_guess_case_insensitive" >:: test_validate_guess_case_insensitive;
    "validate_guess_multiple_configs" >:: test_validate_guess_multiple_configs;
    "validate_guess_edge_cases" >:: test_validate_guess_edge_cases;
  ]

let () = run_test_tt_main suite

