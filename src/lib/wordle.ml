module type Config = sig
  val word_length : int
end

module Make (C : Config) = struct
  let word_length = C.word_length

  (* Capture utils functions before Utils module shadows them *)
  module Base_utils = Utils

  module Feedback = struct
    type color = Green | Yellow | Grey
    type t = color list
    type feedback = {
      guess : string;
      colors : t;
    }
    
    let generate _guess _answer = failwith "Not implemented"
    let make_feedback _guess _answer = failwith "Not implemented"
    let is_correct _fb = failwith "Not implemented"
    let color_to_string _c = failwith "Not implemented"
    let to_string _fb = failwith "Not implemented"
    let colors_to_string _colors = failwith "Not implemented"
  end

  module Game = struct
    type t = Feedback.t list
    let step _game_state _guess = failwith "Not implemented"
  end

  module Utils = struct
    let validate_length s = Base_utils.validate_length ~word_length s
    let validate_guess s = Base_utils.validate_guess ~word_length s
  end
end

