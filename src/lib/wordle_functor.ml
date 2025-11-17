(** Wordle functor implementation - stub for now *)

open Config

module Make (C : Config) = struct
  let word_length = C.word_length

  module Guess = Guess.Make (C)
  module Game = Game.Make (Guess)
  module Utils = Utils.Make (C)
  module Solver = Solver.Make (Guess)
end

