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

(** Checks if a word is valid by calling Datamuse API *)
let is_valid_word_api word =
  let normalized = normalize_word word in
  try
    (* Use Datamuse API to validate word - query with exact spelling match *)
    let api_url = Printf.sprintf "https://api.datamuse.com/words?sp=%s&max=1" normalized in
    let command = Printf.sprintf "curl -s \"%s\"" api_url in
    let ic = Core_unix.open_process_in command in
    let response = In_channel.input_all ic in
    let exit_status = Core_unix.close_process_in ic in
    
    (* Wait for process to complete and check exit status *)
    match exit_status with
    | Ok () ->
        (* Check if response contains the word - Datamuse returns JSON array *)
        if String.is_empty response || not (String.is_prefix response ~prefix:"[") then
          false
        else if String.equal response "[]" then
          (* Empty array means word not found *)
          false
        else
          (* Check if the word appears in the response *)
          (* Datamuse returns: [{"word":"word","score":...}] if found *)
          let word_pattern = Printf.sprintf "\"word\":\"%s\"" normalized in
          String.is_substring response ~substring:word_pattern
    | Error _ -> false  (* Process failed *)
  with
  | _ -> false  (* On any error, return false *)

(** Fetches words from Random Word API - single API call for all words
    Random Word API supports length parameter to get words of a specific length
    Returns all words matching the length in a single request (no API key needed) *)
let fetch_words_from_random_word_api ~word_length =
  try
    (* Random Word API: use length parameter and request a large number of words *)
    (* Request 10000 words to get comprehensive coverage *)
    let api_url = Printf.sprintf "https://random-word-api.herokuapp.com/word?length=%d&number=10000" word_length in
    let command = Printf.sprintf "curl -s \"%s\"" api_url in
    let ic = Core_unix.open_process_in command in
    let response = In_channel.input_all ic in
    ignore (Core_unix.close_process_in ic);
    
    (* Parse JSON response using yojson - returns simple array: ["word1", "word2", ...] *)
    if String.is_empty response then
      []
    else
      try
        let json = Yojson.Safe.from_string response in
        (* Random Word API returns a simple JSON array of strings *)
        let words = 
          json
          |> Yojson.Safe.Util.to_list 
          |> List.map ~f:Yojson.Safe.Util.to_string
          |> List.map ~f:normalize_word
        in
        List.dedup_and_sort words ~compare:String.compare
      with
      | Yojson.Safe.Util.Type_error (msg, _) ->
          Printf.eprintf "JSON parsing error: %s\n" msg;
          []
      | e ->
          Printf.eprintf "Error parsing Random Word API response: %s\n" (Exn.to_string e);
          []
  with
  | e ->
      Printf.eprintf "Error calling Random Word API: %s\n" (Exn.to_string e);
      []

(** Fetches words from Random Word API - single API call for all words
    No API key required - no fallback to local files *)
let fetch_words_from_api ~word_length =
  fetch_words_from_random_word_api ~word_length

(** Loads words from Random Word API only - no fallback to local files
    No API key required - returns empty list if API fails *)
let load_words_from_api ~word_length =
  if word_length < 2 || word_length > 10 then
    raise (Invalid_argument (Printf.sprintf "Word length %d not supported. Must be between 2 and 10." word_length))
  else
    (* Fetch words from Random Word API only - no local file fallback *)
    fetch_words_from_api ~word_length

(** Loads answers from local files
    Answers are always loaded from local files, not from API *)
let load_answers_from_file ~word_length =
  if word_length < 2 || word_length > 10 then
    raise (Invalid_argument (Printf.sprintf "Word length %d not supported. Must be between 2 and 10." word_length))
  else
    let answers_file = Printf.sprintf "data/%dletter/answers.txt" word_length in
    load_dictionary answers_file

(** Loads words from Random Word API (for guesses) and answers from local files
    Returns (words, answers) tuple where:
    - words: loaded from Random Word API only (for solver guesses and user guesses) - no local file fallback
    - answers: loaded from local files (for game answers) *)
let load_dictionary_by_length_api n =
  let words = load_words_from_api ~word_length:n in
  let answers = load_answers_from_file ~word_length:n in
  (words, answers)
