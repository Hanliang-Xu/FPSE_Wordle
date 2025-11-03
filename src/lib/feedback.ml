type color = Green | Yellow | Grey

type t = color list

type feedback = {
    guess : string;
    colors : t;
}
