(** Dictionary module implementation *)

(* TODO: Implement these functions *)

let supported_lengths = [2; 3; 4; 5; 6; 7; 8; 9; 10]

let filter_by_length _words _n =
  failwith "Not implemented yet"

let load_dictionary _filename =
  failwith "Not implemented yet"

let load_dictionary_by_length n =
  if n < 2 || n > 10 then
    raise (Invalid_argument (Printf.sprintf "Word length %d not supported. Must be between 2 and 10." n))
  else
    failwith "Not implemented yet"

let is_valid_word _word _dictionary =
  failwith "Not implemented yet"

let get_random_word _dictionary =
  failwith "Not implemented yet"

let normalize_word _word =
  failwith "Not implemented yet"

let word_count _dictionary =
  failwith "Not implemented yet"
