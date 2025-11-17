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

let suite =
  "Dict module tests" >::: [
    "normalize_word" >:: test_normalize_word;
    "word_count" >:: test_word_count;
    "filter_by_length" >:: test_filter_by_length;
    "load_dictionary" >:: test_load_dictionary;
    "load_dictionary_by_length" >:: test_load_dictionary_by_length;
    "load_dictionary_by_length_invalid" >:: test_load_dictionary_by_length_invalid;
    "is_valid_word" >:: test_is_valid_word;
    "get_random_word" >:: test_get_random_word;
    "supported_lengths" >:: test_supported_lengths;
    "load_dictionary_file_not_found" >:: test_load_dictionary_file_not_found;
    "load_dictionary_filters_empty_lines" >:: test_load_dictionary_filters_empty_lines;
  ]

let () = run_test_tt_main suite

