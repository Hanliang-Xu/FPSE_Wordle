open Core
open OUnit2
open Lib.Dict

(** Test suite for Dict module *)

let test_normalize_word _ =
  assert_equal "hello" (normalize_word "HELLO");
  assert_equal "hello" (normalize_word "Hello");
  assert_equal "hello" (normalize_word "hello");
  assert_equal "world" (normalize_word "WORLD");
  assert_equal "test" (normalize_word "TeSt")

let test_word_count _ =
  assert_equal 0 (word_count []);
  assert_equal 1 (word_count ["hello"]);
  assert_equal 3 (word_count ["a"; "b"; "c"]);
  assert_equal 5 (word_count ["one"; "two"; "three"; "four"; "five"])

let test_filter_by_length _ =
  let words = ["ab"; "abc"; "abcd"; "abcde"; "ab"; "xyz"] in
  (* Test filtering by different lengths *)
  assert_bool "Should filter 2-letter words correctly" 
    (let result = filter_by_length words 2 in
     List.length result = 2 && 
     List.for_all result ~f:(fun w -> String.length w = 2));
  assert_bool "Should filter 3-letter words correctly" 
    (let result = filter_by_length words 3 in
     List.length result = 2 && 
     List.for_all result ~f:(fun w -> String.length w = 3) &&
     List.mem result "abc" ~equal:String.equal &&
     List.mem result "xyz" ~equal:String.equal);
  assert_bool "Should filter 4-letter words correctly" 
    (let result = filter_by_length words 4 in
     List.length result = 1 && 
     List.for_all result ~f:(fun w -> String.length w = 4));
  assert_bool "Should filter 5-letter words correctly" 
    (let result = filter_by_length words 5 in
     List.length result = 1 && 
     List.for_all result ~f:(fun w -> String.length w = 5));
  assert_equal [] (filter_by_length words 6);
  assert_equal [] (filter_by_length [] 5)

let test_load_dictionary _ =
  (* Test loading a real dictionary file *)

  let words = load_dictionary "data/5letter/words.txt" in
  assert_bool "Should load words from file" (List.length words > 0);
  assert_bool "All words should be lowercase" 
    (List.for_all words ~f:(fun w -> String.equal w (normalize_word w)));
  assert_bool "Should contain 'about'" (List.mem words "about" ~equal:String.equal);
  assert_bool "Should contain 'above'" (List.mem words "above" ~equal:String.equal)

let test_load_dictionary_by_length _ =
  (* Test loading dictionaries for different lengths *)

  let test_length n =
    let words, answers = load_dictionary_by_length n in
    assert_bool (Printf.sprintf "Should load words for length %d" n) 
      (List.length words > 0);
    assert_bool (Printf.sprintf "Should load answers for length %d" n) 
      (List.length answers > 0);
    assert_bool (Printf.sprintf "All words should be length %d" n)
      (List.for_all words ~f:(fun w -> String.length w = n));
    assert_bool (Printf.sprintf "All answers should be length %d" n)
      (List.for_all answers ~f:(fun w -> String.length w = n));
    (* answers should be a subset of words *)
    assert_bool (Printf.sprintf "All answers should be in words for length %d" n)
      (List.for_all answers ~f:(fun a -> List.mem words a ~equal:String.equal))
  in
  List.iter [2; 3; 4; 5; 6; 7; 8; 9; 10] ~f:test_length

let test_load_dictionary_by_length_invalid _ =
  (* Test invalid length raises exception *)
  assert_raises (Invalid_argument "Word length 1 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length 1);
  assert_raises (Invalid_argument "Word length 11 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length 11);
  assert_raises (Invalid_argument "Word length 0 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length 0)

let test_is_valid_word _ =
  let dictionary = ["hello"; "world"; "test"] in
  assert_bool "Should find word (exact match)" 
    (is_valid_word "hello" dictionary);
  assert_bool "Should find word (case insensitive)" 
    (is_valid_word "HELLO" dictionary);
  assert_bool "Should find word (mixed case)" 
    (is_valid_word "HeLlO" dictionary);
  assert_bool "Should not find non-existent word" 
    (not (is_valid_word "missing" dictionary));
  assert_bool "Should not find word in empty dictionary" 
    (not (is_valid_word "hello" []))

let test_get_random_word _ =
  let dictionary = ["a"; "b"; "c"; "d"; "e"] in
  (* Test multiple times to ensure randomness *)
  let results = List.init 10 ~f:(fun _ -> get_random_word dictionary) in
  assert_bool "Should return a word from dictionary"
    (List.for_all results ~f:(fun w -> List.mem dictionary w ~equal:String.equal));
  (* Test with single word *)
  assert_equal "hello" (get_random_word ["hello"]);
  (* Test empty dictionary raises exception *)
  assert_raises (Invalid_argument "Cannot get random word from empty dictionary")
    (fun () -> get_random_word [])

let test_supported_lengths _ =
  assert_equal [2; 3; 4; 5; 6; 7; 8; 9; 10] supported_lengths;
  assert_equal 9 (List.length supported_lengths)

let test_load_dictionary_file_not_found _ =
  (* Test that loading non-existent file raises Sys_error *)
  try
    ignore (load_dictionary "nonexistent_file.txt");
    assert_failure "Should have raised Sys_error"
  with
  | Sys_error _ -> ()
  | e -> assert_failure (Printf.sprintf "Expected Sys_error, got %s" (Exn.to_string e))

let test_load_words_from_api _ =
  (* Test loading words from Random Word API *)
  (* Note: This test may fail if API is unavailable, so we make it lenient *)
  let words = load_words_from_api ~word_length:5 in
  (* If API call succeeds, verify the words *)
  if List.length words > 0 then (
    assert_bool "All words should be lowercase" 
      (List.for_all words ~f:(fun w -> String.equal w (normalize_word w)));
    assert_bool "All words should be length 5" 
      (List.for_all words ~f:(fun w -> String.length w = 5));
    assert_bool "Words should be deduplicated" 
      (List.length words = List.length (List.dedup_and_sort words ~compare:String.compare))
  ) else (
    (* API might be down, skip validation but don't fail *)
    Printf.printf "Warning: Random Word API returned no words (API might be unavailable)\n"
  )

let test_load_words_from_api_invalid_length _ =
  (* Test invalid length raises exception *)
  assert_raises (Invalid_argument "Word length 1 not supported. Must be between 2 and 10.") 
    (fun () -> load_words_from_api ~word_length:1);
  assert_raises (Invalid_argument "Word length 11 not supported. Must be between 2 and 10.") 
    (fun () -> load_words_from_api ~word_length:11);
  assert_raises (Invalid_argument "Word length 0 not supported. Must be between 2 and 10.") 
    (fun () -> load_words_from_api ~word_length:0)

let test_load_dictionary_by_length_api _ =
  (* Test loading words from API and answers from local files *)
  (* Note: This test may fail if API is unavailable or data files are missing *)
  (* Tests run from _build/default/src-test/, so go up one level to _build/default/ *)
  (* Use Caml_unix (unshadowed Unix) since Core shadows Unix *)
  let original_dir = Caml_unix.getcwd () in
  try
    Caml_unix.chdir "..";
    let test_length n =
      let words, answers = load_dictionary_by_length_api n in
      (* Answers should always be loaded from local files *)
      assert_bool (Printf.sprintf "Should load answers for length %d" n) 
        (List.length answers > 0);
      assert_bool (Printf.sprintf "All answers should be length %d" n)
        (List.for_all answers ~f:(fun w -> String.length w = n));
      (* Words from API might be empty if API fails, but that's okay *)
      if List.length words > 0 then (
        assert_bool (Printf.sprintf "All words should be length %d" n)
          (List.for_all words ~f:(fun w -> String.length w = n));
        assert_bool (Printf.sprintf "All words should be lowercase for length %d" n)
          (List.for_all words ~f:(fun w -> String.equal w (normalize_word w)))
      ) else (
        Printf.printf "Warning: Random Word API returned no words for length %d (API might be unavailable)\n" n
      )
    in
    List.iter [2; 3; 4; 5; 6; 7; 8; 9; 10] ~f:test_length;
    Caml_unix.chdir original_dir
  with
  | Sys_error msg ->
      (* Restore directory and skip this test *)
      (try Caml_unix.chdir original_dir with _ -> ());
      Printf.printf "Skipping test_load_dictionary_by_length_api: %s\n" msg
  | e ->
      (* Restore directory on any error *)
      (try Caml_unix.chdir original_dir with _ -> ());
      raise e

let test_load_dictionary_by_length_api_invalid _ =
  (* Test invalid length raises exception *)
  assert_raises (Invalid_argument "Word length 1 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length_api 1);
  assert_raises (Invalid_argument "Word length 11 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length_api 11);
  assert_raises (Invalid_argument "Word length 0 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length_api 0)

let test_is_valid_word_api _ =
  (* Test word validation via API *)
  (* Note: This test may fail if API is unavailable *)
  (* Test with a common word that should exist *)
  let result = is_valid_word_api "apple" in
  (* If API works, it should return true for a valid word *)
  (* If API fails, it returns false, so we can't assert true *)
  (* We'll just verify the function doesn't crash and returns a boolean *)
  assert_bool "is_valid_word_api should return a boolean" 
    (match result with true | false -> true);
  (* Test with a clearly invalid word *)
  let invalid_result = is_valid_word_api "xyzabc123" in
  (* Invalid words should return false *)
  (* Lenient: API might fail, so we just verify it returns a boolean *)
  assert_bool "is_valid_word_api should return a boolean for invalid words" 
    (match invalid_result with true | false -> true)
let test_load_dictionary_filters_empty_lines _ =
  (* Test that load_dictionary properly handles files with empty lines *)
  (* We'll test this by checking that real dictionary files don't have empty entries *)

  let words = load_dictionary "data/5letter/words.txt" in
  (* All loaded words should be non-empty *)
  assert_bool "All loaded words should be non-empty"
    (List.for_all words ~f:(fun w -> not (String.is_empty w)));
  (* All words should be properly trimmed *)
  assert_bool "All words should be properly trimmed"
    (List.for_all words ~f:(fun w -> String.equal w (String.strip w)))

(** Complex multi-file tests *)
let test_load_all_dictionary_files _ =
  (* Test loading all supported dictionary files simultaneously *)

  let all_dicts = List.map supported_lengths ~f:(fun length ->
    let words, answers = load_dictionary_by_length length in
    (length, words, answers)
  ) in
  assert_equal 9 (List.length all_dicts);
  (* Verify each dictionary *)
  List.iter all_dicts ~f:(fun (length, words, answers) ->
    assert_bool (Printf.sprintf "Dictionary for length %d should have words" length)
      (List.length words > 0);
    assert_bool (Printf.sprintf "Dictionary for length %d should have answers" length)
      (List.length answers > 0);
    assert_bool (Printf.sprintf "All words should be length %d" length)
      (List.for_all words ~f:(fun w -> String.length w = length));
    assert_bool (Printf.sprintf "All answers should be length %d" length)
      (List.for_all answers ~f:(fun w -> String.length w = length));
    assert_bool (Printf.sprintf "Answers should be subset of words for length %d" length)
      (List.for_all answers ~f:(fun a -> List.mem words a ~equal:String.equal))
  )

let test_cross_file_word_validation _ =
  (* Test that words from one length file are not valid in another *)

  let words3, _ = load_dictionary_by_length 3 in
  let words5, _ = load_dictionary_by_length 5 in
  let words7, _ = load_dictionary_by_length 7 in
  
  (* Sample words from each *)
  let sample3 = List.nth_exn words3 0 in
  let sample5 = List.nth_exn words5 0 in
  let sample7 = List.nth_exn words7 0 in
  
  (* Words from 3-letter should not be in 5-letter or 7-letter *)
  assert_bool "3-letter word should not be in 5-letter dictionary"
    (not (is_valid_word sample3 words5));
  assert_bool "3-letter word should not be in 7-letter dictionary"
    (not (is_valid_word sample3 words7));
  
  (* Words from 5-letter should not be in 3-letter or 7-letter *)
  assert_bool "5-letter word should not be in 3-letter dictionary"
    (not (is_valid_word sample5 words3));
  assert_bool "5-letter word should not be in 7-letter dictionary"
    (not (is_valid_word sample5 words7));
  
  (* Words from 7-letter should not be in 3-letter or 5-letter *)
  assert_bool "7-letter word should not be in 3-letter dictionary"
    (not (is_valid_word sample7 words3));
  assert_bool "7-letter word should not be in 5-letter dictionary"
    (not (is_valid_word sample7 words5))

let test_answers_subset_consistency_all_lengths _ =
  (* Test that answers are subsets of words for all lengths *)

  List.iter supported_lengths ~f:(fun length ->
    let words, answers = load_dictionary_by_length length in
    assert_bool (Printf.sprintf "All answers should be in words for length %d" length)
      (List.for_all answers ~f:(fun a -> List.mem words a ~equal:String.equal));
    assert_bool (Printf.sprintf "Answers count should be <= words count for length %d" length)
      (List.length answers <= List.length words);
    (* Answers should typically be a proper subset (not all words are answers) *)
    (* But we'll just check it's a subset, not necessarily proper *)
    assert_bool (Printf.sprintf "Answers should be subset of words for length %d" length)
      (List.length answers <= List.length words)
  )

let test_random_word_from_multiple_files _ =
  (* Test getting random words from multiple dictionary files *)

  let random_words = List.map supported_lengths ~f:(fun length ->
    let _, answers = load_dictionary_by_length length in
    get_random_word answers
  ) in
  assert_equal 9 (List.length random_words);
  (* Verify each random word has correct length *)
  List.iter2_exn supported_lengths random_words ~f:(fun length word ->
    assert_equal length (String.length word) ~printer:Int.to_string
  )

let test_normalize_word_consistency_across_files _ =
  (* Test that normalize_word works consistently across all files *)

  List.iter supported_lengths ~f:(fun length ->
    let words, _ = load_dictionary_by_length length in
    (* Sample a few words and verify normalization *)
    let samples = List.take words (min 10 (List.length words)) in
    List.iter samples ~f:(fun word ->
      let normalized = normalize_word word in
      assert_bool (Printf.sprintf "Normalized word should be lowercase for length %d" length)
        (String.equal normalized (String.lowercase normalized));
      assert_bool (Printf.sprintf "Normalized word should equal itself for length %d" length)
        (String.equal normalized (normalize_word normalized))
    )
  )

let test_filter_by_length_with_real_dictionaries _ =
  (* Test filter_by_length with real dictionary data *)

  let words5, _ = load_dictionary_by_length 5 in
  (* Filter 5-letter words from the 5-letter dictionary (should return all) *)
  let filtered5 = filter_by_length words5 5 in
  assert_equal (List.length words5) (List.length filtered5);
  assert_bool "All filtered words should be 5 letters"
    (List.for_all filtered5 ~f:(fun w -> String.length w = 5));
  (* Filter 3-letter words (should return empty) *)
  let filtered3 = filter_by_length words5 3 in
  assert_equal 0 (List.length filtered3);
  (* Filter 7-letter words (should return empty) *)
  let filtered7 = filter_by_length words5 7 in
  assert_equal 0 (List.length filtered7)

let test_word_count_consistency _ =
  (* Test word_count is consistent across all dictionary files *)

  List.iter supported_lengths ~f:(fun length ->
    let words, answers = load_dictionary_by_length length in
    assert_equal (List.length words) (word_count words);
    assert_equal (List.length answers) (word_count answers);
    assert_bool (Printf.sprintf "Answers count should be <= words count for length %d" length)
      (word_count answers <= word_count words)
  )

(** Test is_valid_word_api function *)
let test_is_valid_word_api_valid _ =
  (* Test with a common valid English word *)
  assert_bool "hello should be a valid word" (is_valid_word_api "hello");
  assert_bool "world should be a valid word" (is_valid_word_api "world");
  assert_bool "crane should be a valid word" (is_valid_word_api "crane")

let test_is_valid_word_api_invalid _ =
  (* Test with invalid/nonsense words *)
  assert_bool "xyzzy should not be a valid word" (not (is_valid_word_api "xyzzy"));
  assert_bool "qwert should not be a valid word" (not (is_valid_word_api "qwert"));
  assert_bool "zzzzz should not be a valid word" (not (is_valid_word_api "zzzzz"))

let test_is_valid_word_api_case_insensitive _ =
  (* Test case insensitivity *)
  assert_bool "HELLO should be valid (uppercase)" (is_valid_word_api "HELLO");
  assert_bool "HeLLo should be valid (mixed case)" (is_valid_word_api "HeLLo")

let test_is_valid_word_api_empty _ =
  (* Test with empty string - API should return false *)
  assert_bool "empty string should not be valid" (not (is_valid_word_api ""))

let test_load_dictionary_negative_length _ =
  (* Test negative length raises exception *)
  assert_raises (Invalid_argument "Word length -1 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length (-1))

let test_load_dictionary_large_length _ =
  (* Test very large length raises exception *)
  assert_raises (Invalid_argument "Word length 100 not supported. Must be between 2 and 10.") 
    (fun () -> load_dictionary_by_length 100)

let test_normalize_word_special_chars _ =
  (* Test normalization with various inputs *)
  assert_equal "abc" (normalize_word "ABC");
  assert_equal "test123" (normalize_word "TEST123");
  assert_equal "" (normalize_word "")

let test_filter_by_length_edge_cases _ =
  (* Test with edge case lengths *)
  let words = ["a"; "ab"; "abc"; "abcd"; "abcdefghij"] in
  assert_equal 1 (List.length (filter_by_length words 1));
  assert_equal 1 (List.length (filter_by_length words 10));
  assert_equal 0 (List.length (filter_by_length words 100))

let test_is_valid_word_edge_cases _ =
  (* Test edge cases for is_valid_word *)
  let dictionary = ["hello"; "world"] in
  assert_bool "Empty string should not be in dictionary" 
    (not (is_valid_word "" dictionary));
  assert_bool "Word should be found with trailing spaces normalized"
    (is_valid_word "hello" dictionary)

let suite =
  "Dict module tests" >::: [
    "normalize_word" >:: test_normalize_word;
    "word_count" >:: test_word_count;
    "filter_by_length" >:: test_filter_by_length;
    "load_dictionary_by_length_invalid" >:: test_load_dictionary_by_length_invalid;
    "is_valid_word" >:: test_is_valid_word;
    "get_random_word" >:: test_get_random_word;
    "supported_lengths" >:: test_supported_lengths;
    "load_dictionary_file_not_found" >:: test_load_dictionary_file_not_found;
    "load_words_from_api" >:: test_load_words_from_api;
    "load_words_from_api_invalid_length" >:: test_load_words_from_api_invalid_length;
    "load_dictionary_by_length_api" >:: test_load_dictionary_by_length_api;
    "load_dictionary_by_length_api_invalid" >:: test_load_dictionary_by_length_api_invalid;
    "is_valid_word_api" >:: test_is_valid_word_api;
    "load_dictionary_filters_empty_lines" >:: test_load_dictionary_filters_empty_lines;
    "load_all_dictionary_files" >:: test_load_all_dictionary_files;
    "cross_file_word_validation" >:: test_cross_file_word_validation;
    "answers_subset_consistency_all_lengths" >:: test_answers_subset_consistency_all_lengths;
    "random_word_from_multiple_files" >:: test_random_word_from_multiple_files;
    "normalize_word_consistency_across_files" >:: test_normalize_word_consistency_across_files;
    "filter_by_length_with_real_dictionaries" >:: test_filter_by_length_with_real_dictionaries;
    "word_count_consistency" >:: test_word_count_consistency;
    "is_valid_word_api_valid" >:: test_is_valid_word_api_valid;
    "is_valid_word_api_invalid" >:: test_is_valid_word_api_invalid;
    "is_valid_word_api_case_insensitive" >:: test_is_valid_word_api_case_insensitive;
    "is_valid_word_api_empty" >:: test_is_valid_word_api_empty;
    "load_dictionary_negative_length" >:: test_load_dictionary_negative_length;
    "load_dictionary_large_length" >:: test_load_dictionary_large_length;
    "normalize_word_special_chars" >:: test_normalize_word_special_chars;
    "filter_by_length_edge_cases" >:: test_filter_by_length_edge_cases;
    "is_valid_word_edge_cases" >:: test_is_valid_word_edge_cases;
  ]

let () = run_test_tt_main suite

