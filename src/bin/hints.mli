(** Hints module for generating and displaying game hints *)

(** Type for cumulative hints *)
type cumulative_hints = {
  mode1_hints : (int * char) list;  (** (position, letter) pairs *)
  mode2_hints : char list;          (** letters without position *)
}

(** Generate hint mode 1: correct letter in correct position *)
val generate_hint_mode1 : answer:string -> guesses_with_colors:(string * Lib.Feedback.color list) list -> int * char

(** Generate hint mode 2: correct letter without position *)
val generate_hint_mode2 : answer:string -> guesses_with_colors:(string * Lib.Feedback.color list) list -> char

(** Display all cumulative hints *)
val display_cumulative_hints : word_length:int -> cumulative_hints -> unit

(** Ask user if they want a hint and provide it, updating cumulative hints *)
val offer_hint : answer:string -> guesses_with_colors:(string * Lib.Feedback.color list) list -> cumulative_hints:cumulative_hints -> cumulative_hints

