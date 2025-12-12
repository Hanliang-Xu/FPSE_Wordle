(** Wordle functor implementation *)

open Config

module Make (C : Config) = struct
  let word_length = C.word_length

  module Guess = Guess.Make (C)
  module Game = Game.Make (Guess)
  module Solver = Solver.Make (C) (Guess)
end
