(** Dictionary module for loading and managing word lists of variable length (2-10 letters)
    
    This module provides functions to work with a list of words of variable length
    with supporting functions for loading, filtering, validating, and selecting words.
    
    Important Notes:
    - Words are loaded from Random Word API (for guesses)
    - Answers are loaded from local files (answers.txt)
    - Players can guess any word from the API, but answers are only 
      selected from answers.txt files.
    
    - answers.txt include common/fair words
      answers.txt contains only common/fair words to ensure a fair and 
      enjoyable game experience.
    
    Supported word lengths: 2, 3, 4, 5, 6, 7, 8, 9, 10 letters
*)

val load_dictionary : string -> string list
(** [load_dictionary filename] reads words from [filename] and returns a list
    of all words found in the file.
    Raises [Sys_error] if the file cannot be read. *)

val filter_by_length : string list -> int -> string list
(** [filter_by_length words n] filters a list of words to only include
    those that are exactly n characters long. *)

val is_valid_word : string -> string list -> bool
(** [is_valid_word word dictionary] returns true if [word] exists in [dictionary].
    Comparison is case-insensitive. *)

val get_random_word : string list -> string
(** [get_random_word dictionary] returns a random word from [dictionary].
    Raises [Invalid_argument] if the dictionary is empty. *)

val normalize_word : string -> string
(** [normalize_word word] converts [word] to lowercase for consistent comparison. *)

val word_count : string list -> int
(** [word_count dictionary] returns the number of words in [dictionary]. *)

val supported_lengths : int list
(** [supported_lengths] returns the list of supported word lengths [2; 3; 4; 5; 6; 7; 8; 9; 10]. *)

val is_valid_word_api : ?url_pattern:string -> string -> bool
(** [is_valid_word_api ?url_pattern word] checks if [word] is valid by calling a dictionary API.
    The optional [url_pattern] allows overriding the API URL pattern (default: "https://api.datamuse.com/words?sp=%s&max=1").
    The pattern should contain %s placeholder for the word.
    Returns true if the word is valid, false otherwise.
    This function makes an HTTP request to validate the word. *)

val load_words_from_api : ?url_pattern:string -> int -> string list
(** [load_words_from_api ?url_pattern word_length] fetches words of the specified length from Random Word API.
    The optional [url_pattern] allows overriding the API URL pattern
    (default: "https://random-word-api.herokuapp.com/word?length=%d&number=10000").
    The pattern should contain %d placeholder for word_length.
    Uses single API call to get all words - no API key required, no fallback to local files.
    Returns a list of normalized (lowercase) words.
    Returns empty list if API fails.
    Raises [Invalid_argument] if word_length is not between 2 and 10. *)

val load_dictionary_by_length_api : ?url_pattern:string -> int -> (string list * string list)
(** [load_dictionary_by_length_api ?url_pattern n] loads words and answers for n-letter words.
    The optional [url_pattern] allows overriding the Random Word API URL pattern
    (default: "https://random-word-api.herokuapp.com/word?length=%d&number=10000").
    Returns (words, answers) tuple where:
    - words: loaded from Random Word API only (for solver guesses and user guesses) - no local file fallback
    - answers: loaded from local files (for game answers)
    Requires: 2 <= n <= 10
    Raises [Invalid_argument] if n is out of range.
    Raises [Sys_error] if answer files cannot be read. *)
