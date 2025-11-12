val validate_length : word_length:int -> string -> bool
(** [validate_length ~word_length s] returns true if [s] has length equal to [word_length] *)

val validate_guess : word_length:int -> string -> (string, string) result
(** [validate_guess ~word_length s] returns [Ok s] if valid, 
    [Error msg] if [s] doesn't have length [word_length] *)

