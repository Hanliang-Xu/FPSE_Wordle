(** Feedback module - defines types for Wordle feedback *)

type color = Green | Yellow | Grey
type t = color list
type feedback = {
    guess : string;
    colors : t;
    distances : int option list option;
    (** Optional list of distances for each position.
        [Some distances] when show_position_distances is enabled.
        [None] when disabled.
        Each element: [Some d] for Yellow letters (d = positions to move, positive = right, negative = left),
                      [None] for Green/Grey letters. *)
}
