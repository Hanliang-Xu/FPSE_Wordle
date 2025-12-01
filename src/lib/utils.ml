(** Utils module implementation *)

open Config

module Make (C : Config) = struct
  let validate_length s =
    String.length s = C.word_length

  let validate_guess s =
    if validate_length s then
      Ok s
    else
      Error (Printf.sprintf "Invalid word length: expected %d, got %d" 
               C.word_length (String.length s))
end

