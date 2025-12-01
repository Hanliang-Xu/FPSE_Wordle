module type Config = sig
  val word_length : int
  (** The length of words in this Wordle game instance *)
end