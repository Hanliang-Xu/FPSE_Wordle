(** Utils module for Wordle game *)

open Config

module Make (C : Config) : sig
  val validate_length : string -> bool
  (** [validate_length s] returns true if [s] has the correct word length *)
  
  val validate_guess : string -> (string, string) result
  (** [validate_guess s] returns [Ok s] if valid, [Error msg] if invalid length *)
end

