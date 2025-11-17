open Core

(** Dictionary module implementation *)

let supported_lengths = [2; 3; 4; 5; 6; 7; 8; 9; 10]

(** Converts a word to lowercase for consistent comparison *)
let normalize_word word =
  String.lowercase word

(** Returns the number of words in a dictionary *)
let word_count dictionary =
  List.length dictionary

(** Filters a list of words to only include those that are exactly n characters long *)
let filter_by_length words n =
  List.filter words ~f:(fun word -> String.length word = n)

(** Reads words from a file and returns a list of all words found in the file *)
let load_dictionary filename =
  try
    let lines = In_channel.read_lines filename in
    let words =
      List.filter_map lines ~f:(fun line ->
          let trimmed = String.strip line in
          if String.is_empty trimmed then None
          else Some (normalize_word trimmed))
    in
    words
  with
  | Sys_error msg -> raise (Sys_error msg)

(** Loads both words and answers dictionaries for n-letter words *)
let load_dictionary_by_length n =
  if n < 2 || n > 10 then
    raise (Invalid_argument (Printf.sprintf "Word length %d not supported. Must be between 2 and 10." n))
  else
    let words_file = Printf.sprintf "data/%dletter/words.txt" n in
    let answers_file = Printf.sprintf "data/%dletter/answers.txt" n in
    let words = load_dictionary words_file in
    let answers = load_dictionary answers_file in
    (words, answers)

(** Checks if a word exists in a dictionary (case-insensitive) *)
let is_valid_word word dictionary =
  let normalized = normalize_word word in
  List.mem dictionary normalized ~equal:String.equal

(** Returns a random word from a dictionary *)
let get_random_word dictionary =
  if List.is_empty dictionary then
    raise (Invalid_argument "Cannot get random word from empty dictionary")
  else
    let len = List.length dictionary in
    let index = Random.int len in
    List.nth_exn dictionary index
