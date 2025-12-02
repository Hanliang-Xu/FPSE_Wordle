(** Feedback granularity - how detailed the feedback is *)
type feedback_granularity =
  | ThreeState  (** Standard Wordle: Green (correct position), Yellow (wrong position), Grey (not in word) *)
  | Binary      (** Simple: Green (correct position), Grey (incorrect position) - no position hints *)

module type Config = sig
  val word_length : int
  (** The length of words in this Wordle game instance *)
  
  val feedback_granularity : feedback_granularity
  (** How detailed the feedback should be.
      Default: [ThreeState] *)
  
  val show_position_distances : bool
  (** Whether to show how many positions away each letter is from its correct position.
      Only applies to Yellow letters (letters in word but wrong position).
      Default: [false] *)
end