(** User interface module for handling user input and configuration *)

(** Prompt user for an integer value *)
val prompt_int : default:int -> min:int -> max:int -> string -> int

(** Prompt user for a boolean value *)
val prompt_bool : default:bool -> string -> bool

(** Prompt user for feedback granularity mode *)
val prompt_feedback_granularity : unit -> Config.feedback_granularity

(** Prompt user for hint mode selection *)
val prompt_hint_mode : unit -> int

(** Get game configuration from user input *)
val get_config : unit -> int * int * bool * Config.feedback_granularity * bool

