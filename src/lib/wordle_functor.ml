(** Wordle functor implementation - stub for now *)

module type Config = sig
  val word_length : int
end

module Make (C : Config) = struct
  let word_length = C.word_length

  module Feedback = Feedback.Make (C)
  module Game = Game.Make (C) (Feedback)
  module Utils = Utils.Make (C)
  module Solver = Solver.Make (Feedback)
end

