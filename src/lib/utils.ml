(** Utils module implementation - stub for now *)

module type Config = sig
  val word_length : int
end

module Make (C : Config) = struct
  let validate_length _s = failwith "Not implemented"
  let validate_guess _s = failwith "Not implemented"
end

