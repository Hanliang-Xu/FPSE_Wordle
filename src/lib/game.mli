(** game.mli *)

type t = Feedback.t list

val step : t -> string -> t