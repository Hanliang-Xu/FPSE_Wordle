(** Dictionary module for loading and managing word lists 
    
    Important Notes:
    - answers.txt 是 words.txt 的子集
      All words in answers.txt are also present in words.txt.
      Players can guess any word from words.txt, but answers are only 
      selected from answers.txt.
    
    - answers.txt 包含常见/公平的单词
      answers.txt contains only common/fair words to ensure a fair and 
      enjoyable game experience. words.txt can include more obscure words 
      that players can use for strategic guessing.
*)

val load_dictionary : string -> string list
(** [load_dictionary filename] reads words from [filename] and returns a list
    of all words found in the file.
    Raises [Sys_error] if the file cannot be read. *)

val load_dictionary_by_length : int -> (string list * string list)
(** [load_dictionary_by_length n] loads both words and answers dictionaries 
    for n-letter words. Returns (words, answers) tuple.
    Requires: 2 <= n <= 10
    Raises [Invalid_argument] if n is out of range.
    Raises [Sys_error] if dictionary files cannot be read. *)

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
