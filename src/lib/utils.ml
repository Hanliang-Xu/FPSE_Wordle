let validate_length ~word_length s = String.length s = word_length

let validate_guess ~word_length s =
  if validate_length ~word_length s then Ok s
  else Error (Printf.sprintf "Guess must be %d characters long" word_length)

