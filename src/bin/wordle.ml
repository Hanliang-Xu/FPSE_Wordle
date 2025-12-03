(** Main entry point for Wordle game *)

open Core

(** Main entry point *)
let main () =
  (* Initialize random number generator *)
  Random.self_init ();
  
  (* Get configuration from user *)
  let word_length, max_guesses, show_hints, feedback_granularity, show_position_distances = 
    Lib.Ui.get_config () 
  in
  
  (* Run the game with the configuration *)
  Lib.Game_loop.run_with_config 
    ~word_length 
    ~max_guesses 
    ~show_hints 
    ~feedback_granularity 
    ~show_position_distances

let () = main ()
