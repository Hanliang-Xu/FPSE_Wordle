type color = Green | Yellow | Grey
(** Represents the color feedback for each letter:
    - [Green]: correct letter in correct position
    - [Yellow]: correct letter in wrong position  
    - [Grey]: letter not in the word *)

type t = color list
(** A list of colors representing feedback for each letter in a guess *)

type feedback = {
    guess : string;
    colors : t;
}
(** A record containing a guess and its corresponding color feedback *)

val generate : string -> string -> t
(** [generate guess answer] returns a list of colors representing the feedback
    for [guess] compared to [answer]. 
    - Green indicates correct letter in correct position
    - Yellow indicates correct letter in wrong position
    - Grey indicates letter not in the answer
    Requires: both [guess] and [answer] are 5-character strings *)

val make_feedback : string -> string -> feedback
(** [make_feedback guess answer] creates a feedback record with the guess
    and its generated colors. 
    Requires: both [guess] and [answer] are 5-character strings *)

val is_correct : feedback -> bool
(** [is_correct fb] returns true if all colors in the feedback are Green,
    indicating a correct guess *)

val color_to_string : color -> string
(** [color_to_string c] converts a color to a string representation *)

val to_string : feedback -> string
(** [to_string fb] converts a feedback record to a human-readable string *)

val colors_to_string : t -> string
(** [colors_to_string colors] converts a color list to a string representation *)
