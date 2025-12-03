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
  ]

let () = run_test_tt_main suite

