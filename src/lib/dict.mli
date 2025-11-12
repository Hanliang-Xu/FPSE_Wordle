(** Dictionary module for loading and managing word lists *)

val load_dictionary : string -> string list
(** [load_dictionary filename] reads words from [filename] and returns a list
    of all 5-character words found in the file.
    The file may contain words directly (one per line) or words separated by
    whitespace or other delimiters. Only 5-character words are included.
    Raises [Sys_error] if the file cannot be read. *)

val filter_five_char_words : string list -> string list
(** [filter_five_char_words words] filters a list of words to only include
    those that are exactly 5 characters long. *)

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

