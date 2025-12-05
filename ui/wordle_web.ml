open Core
open Lib

(* -- Global Game State -- 
   In a real app, this would be stored in a session or database. 
   For this demo, we use a global mutable reference.
*)

(* Replicate the terminal app's configuration options *)
type game_config = {
  word_length: int;
  max_guesses: int;
  feedback_granularity: Config.feedback_granularity;
  show_position_distances: bool;
}

(* Cumulative hints state tracking *)
type cumulative_hints = {
  mode1_hints : (int * char) list;  (* (position, letter) pairs *)
  mode2_hints : char list;          (* letters without position *)
}

let empty_hints = { mode1_hints = []; mode2_hints = [] }

(* Define the interface for the active game to abstract over the functor *)
module type ActiveGame_S = sig
  module W : sig
    module Game : sig
      type t
      val init : answer:string -> max_guesses:int -> t
      val step : t -> string -> t
      val num_guesses : t -> int
      val is_won : t -> bool
      val get_board : t -> Feedback.feedback list
      val last_feedback : t -> Feedback.feedback option
      val remaining_guesses : t -> int
      val is_over : t -> bool
      val can_guess : t -> bool
      val answer : t -> string
    end
    module Solver : sig
      type t
      val create : string list -> t
      val make_guess : t -> string
      val update : t -> Feedback.feedback -> t
      val candidate_count : t -> int
    end
    module Utils : sig
      val validate_guess : string -> (string, string) result
    end
  end
  
  val game_state : W.Game.t ref
  val solver_state : W.Solver.t ref
  val config : game_config
  val cumulative_hints : cumulative_hints ref
  val word_list : string list
  val answer : string
end

(* The global mutable reference to the current active game *)
let current_game : (module ActiveGame_S) option ref = ref None

(* Helper to create a new game with specific config *)
let start_game (cfg : game_config) =
  (* Define the Config module dynamically based on input *)
  let module C = struct
    let word_length = cfg.word_length
    let feedback_granularity = cfg.feedback_granularity
    let show_position_distances = cfg.show_position_distances
  end in
  
  (* Instantiate the Wordle functor *)
  let module W_Instance = Wordle_functor.Make(C) in
  
  (* Load dictionary *)
  let (words, answers) = Dict.load_dictionary_by_length_api cfg.word_length in
  let answer = Dict.get_random_word answers in
  
  (* Create the active game module *)
  let module Active : ActiveGame_S = struct
    module W = struct
      include W_Instance
      module Game = struct
         include W_Instance.Game
         let answer t = t.answer
      end
    end
    
    let game_state = ref (W.Game.init ~answer ~max_guesses:cfg.max_guesses)
    let solver_state = ref (W.Solver.create words)
    let config = cfg
    let cumulative_hints = ref empty_hints
    let word_list = words
    let answer = answer
  end in
  
  current_game := Some (module Active)

(* -- JSON Helpers -- *)

let feedback_color_to_string = function
  | Feedback.Green -> "correct"
  | Feedback.Yellow -> "present"
  | Feedback.Grey -> "absent"

let feedback_to_json (fb : Feedback.feedback) =
  let colors_json = 
    List.map fb.colors ~f:(fun c -> sprintf "\"%s\"" (feedback_color_to_string c))
    |> String.concat ~sep:","
  in
  let distances_json = 
    match fb.distances with
    | None -> "null"
    | Some dists -> 
        List.map dists ~f:(function
          | None -> "null"
          | Some d -> Int.to_string d
        )
        |> String.concat ~sep:","
        |> sprintf "[%s]"
  in
  sprintf "{\"guess\":\"%s\",\"colors\":[%s],\"distances\":%s}" fb.guess colors_json distances_json

let board_to_json board =
  let feedbacks = List.map board ~f:feedback_to_json |> String.concat ~sep:"," in
  sprintf "[%s]" feedbacks

(* Hint Generation Helpers *)

(* Mode 1: Correct letter in correct position *)
let generate_hint_mode1 ~answer ~guesses_with_colors =
  let word_length = String.length answer in
  let revealed_positions = 
    List.fold guesses_with_colors ~init:(Set.empty (module Int)) ~f:(fun acc (_, colors) ->
      List.foldi colors ~init:acc ~f:(fun idx acc' color ->
        match color with
        | Feedback.Green -> Set.add acc' idx
        | _ -> acc'
      )
    )
  in
  let available_positions = 
    List.filter (List.range 0 word_length) ~f:(fun pos ->
      not (Set.mem revealed_positions pos)
    )
  in
  match available_positions with
  | [] -> 
      let pos = Random.int word_length in
      (pos, String.get answer pos)
  | positions ->
      let pos = List.nth_exn positions (Random.int (List.length positions)) in
      (pos, String.get answer pos)

(* Mode 2: Correct letter without position *)
let generate_hint_mode2 ~answer ~guesses_with_colors =
  let revealed_letters = 
    List.fold guesses_with_colors ~init:(Set.empty (module Char)) ~f:(fun acc (guess, colors) ->
      List.fold2_exn (String.to_list guess) colors ~init:acc ~f:(fun acc' char color ->
        match color with
        | Feedback.Green | Feedback.Yellow -> Set.add acc' char
        | _ -> acc'
      )
    )
  in
  let answer_letters = String.to_list answer |> List.dedup_and_sort ~compare:Char.compare in
  let unrevealed_letters = 
    List.filter answer_letters ~f:(fun c -> not (Set.mem revealed_letters c))
  in
  match unrevealed_letters with
  | [] ->
      let idx = Random.int (String.length answer) in
      String.get answer idx
  | letters ->
      List.nth_exn letters (Random.int (List.length letters))

(* -- API Handlers -- *)

let new_game_handler request =
  let%lwt body = Dream.body request in
  let config = 
    try
      let json = Yojson.Safe.from_string body in
      let open Yojson.Safe.Util in
      {
        word_length = json |> member "wordLength" |> to_int_option |> Option.value ~default:5;
        max_guesses = json |> member "maxGuesses" |> to_int_option |> Option.value ~default:6;
        feedback_granularity = (
          match json |> member "feedbackMode" |> to_string_option with
          | Some "binary" -> Config.Binary
          | _ -> Config.ThreeState
        );
        show_position_distances = json |> member "showDistances" |> to_bool_option |> Option.value ~default:false;
      }
    with _ -> 
      { word_length = 5; max_guesses = 6; feedback_granularity = Config.ThreeState; show_position_distances = false }
  in
  
  try 
    start_game config;
    Dream.json "{\"status\":\"success\",\"message\":\"New game started\"}"
  with 
  | Invalid_argument msg -> 
      Dream.json ~status:`Bad_Request (sprintf "{\"status\":\"error\",\"message\":\"%s\"}" msg)
  | _ ->
      Dream.json ~status:`Internal_Server_Error "{\"status\":\"error\",\"message\":\"Failed to start game\"}"

let guess_handler request =
  let%lwt body = Dream.body request in
  match !current_game with
  | None -> 
      start_game { word_length=5; max_guesses=6; feedback_granularity=Config.ThreeState; show_position_distances=false };
      Dream.json ~status:`Bad_Request "{\"status\":\"error\",\"message\":\"No active game (started default)\"}"
  | Some (module Active) ->
      let guess = 
        try
          let json = Yojson.Safe.from_string body in
          Yojson.Safe.Util.(json |> member "guess" |> to_string) |> String.lowercase
        with _ -> ""
      in
      
      match Active.W.Utils.validate_guess guess with
      | Error msg -> 
          Dream.json ~status:`Bad_Request (sprintf "{\"status\":\"error\",\"message\":\"%s\"}" msg)
      | Ok valid_guess ->
          (* Check if valid word in dictionary *)
          if not (Dict.is_valid_word_api valid_guess) then
             Dream.json ~status:`Bad_Request "{\"status\":\"error\",\"message\":\"Not a valid word\"}"
          else if not (Active.W.Game.can_guess !(Active.game_state)) then
             Dream.json ~status:`Bad_Request "{\"status\":\"error\",\"message\":\"Game is over\"}"
          else (
            let new_game_state = Active.W.Game.step !(Active.game_state) valid_guess in
            Active.game_state := new_game_state;
            
            let feedback = 
              match Active.W.Game.last_feedback new_game_state with
              | Some fb -> fb
              | None -> failwith "Should have feedback"
            in
            
            let new_solver_state = Active.W.Solver.update !(Active.solver_state) feedback in
            Active.solver_state := new_solver_state;
            
            let is_won = Active.W.Game.is_won new_game_state in
            let is_over = Active.W.Game.is_over new_game_state in
            let remaining = Active.W.Game.remaining_guesses new_game_state in
            
            let answer_json = 
              if is_over && not is_won then
                sprintf ",\"answer\":\"%s\"" Active.answer
              else ""
            in
            
            (* If game is over, run solver and add comparison *)
            let comparison_json =
              if is_over then (
                (* Run solver to completion *)
                let solver_game = Active.W.Game.init 
                  ~answer:Active.answer
                  ~max_guesses:Active.config.max_guesses in
                let solver_state = Active.W.Solver.create Active.word_list in
                let rec solver_loop game_state solver_state =
                  if Active.W.Game.is_over game_state then
                    (Active.W.Game.is_won game_state, Active.W.Game.num_guesses game_state)
                  else (
                    let guess = Active.W.Solver.make_guess solver_state in
                    let new_game_state = Active.W.Game.step game_state guess in
                    let feedback =
                      match Active.W.Game.last_feedback new_game_state with
                      | Some fb -> fb
                      | None -> failwith "Unexpected: no feedback after step"
                    in
                    let new_solver_state = Active.W.Solver.update solver_state feedback in
                    solver_loop new_game_state new_solver_state
                  )
                in
                let solver_won, solver_guesses = solver_loop solver_game solver_state in
                let human_guesses = Active.W.Game.num_guesses new_game_state in
                sprintf ",\"comparison\":{\"humanWon\":%b,\"humanGuesses\":%d,\"botWon\":%b,\"botGuesses\":%d}"
                  is_won human_guesses solver_won solver_guesses
              ) else ""
            in
            
            let response = sprintf 
              "{\"status\":\"success\",\"feedback\":%s,\"isWon\":%b,\"isOver\":%b,\"remaining\":%d%s%s}"
              (feedback_to_json feedback) is_won is_over remaining answer_json comparison_json
            in
            Dream.json response
          )

let hint_handler request =
  let%lwt body = Dream.body request in
  match !current_game with
  | None -> Dream.json ~status:`Bad_Request "{\"status\":\"error\",\"message\":\"No active game\"}"
  | Some (module Active) ->
      let mode = 
        try
          let json = Yojson.Safe.from_string body in
          Yojson.Safe.Util.(json |> member "mode" |> to_int)
        with _ -> 1
      in
      
      let game = !(Active.game_state) in
      let answer = Active.W.Game.answer game in
      let current_board = Active.W.Game.get_board game in
      let guesses_with_colors = 
        List.map current_board ~f:(fun fb -> (fb.guess, fb.colors))
      in
      
      match mode with
      | 1 -> (* Position Hint *)
          let pos, letter = generate_hint_mode1 ~answer ~guesses_with_colors in
          (* Update cumulative hints *)
          let current = !(Active.cumulative_hints) in
          if not (List.exists current.mode1_hints ~f:(fun (p, _) -> p = pos)) then
            Active.cumulative_hints := { current with mode1_hints = current.mode1_hints @ [(pos, letter)] };
          
          Dream.json (sprintf "{\"status\":\"success\",\"type\":\"position\",\"pos\":%d,\"letter\":\"%c\"}" pos letter)
          
      | 2 -> (* Letter Hint *)
          let letter = generate_hint_mode2 ~answer ~guesses_with_colors in
          (* Update cumulative hints *)
          let current = !(Active.cumulative_hints) in
          if not (List.mem current.mode2_hints letter ~equal:Char.equal) then
            Active.cumulative_hints := { current with mode2_hints = current.mode2_hints @ [letter] };
            
          Dream.json (sprintf "{\"status\":\"success\",\"type\":\"letter\",\"letter\":\"%c\"}" letter)
          
      | _ -> Dream.json ~status:`Bad_Request "{\"status\":\"error\",\"message\":\"Invalid hint mode\"}"

let state_handler _request =
  match !current_game with
  | None -> Dream.json "{\"status\":\"error\",\"message\":\"No active game\"}"
  | Some (module Active) ->
      let game = !(Active.game_state) in
      let board_json = board_to_json (Active.W.Game.get_board game) in
      let response = sprintf
        "{\"board\":%s,\"remaining\":%d,\"isWon\":%b,\"isOver\":%b,\"wordLength\":%d}"
        board_json
        (Active.W.Game.remaining_guesses game)
        (Active.W.Game.is_won game)
        (Active.W.Game.is_over game)
        Active.config.word_length
      in
      Dream.json response

let index_handler _request =
  Dream.html {|
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wordle - Advanced OCaml Wordle</title>
    <link rel="stylesheet" href="/static/styles.css">
    <link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="logo-section">
                <h1 class="title">WordCraft</h1>
                <div class="subtitle">Advanced Configurable Wordle</div>
            </div>
            <div class="header-controls">
                <button class="btn btn-primary" id="newGameBtn">New Game</button>
            </div>
        </header>

        <div class="solver-panel" id="solverPanel">
            <div class="solver-header">
                <h3>Solver Hints</h3>
            </div>
            <div class="solver-content">
                <div class="stat-item">
                    <span class="stat-label">Next Best Guess:</span>
                    <span class="stat-value" id="solverHint">-</span>
                </div>
                <div class="stat-item">
                    <span class="stat-label">Remaining Candidates:</span>
                    <span class="stat-value" id="candidateCount">-</span>
                </div>
            </div>
        </div>

        <div class="hint-controls" id="hintControls" style="display: none;">
            <button class="btn btn-secondary btn-small" onclick="requestHint(1)">Reveal Position</button>
            <button class="btn btn-secondary btn-small" onclick="requestHint(2)">Reveal Letter</button>
        </div>
        <div id="hintDisplay" class="hint-display"></div>

        <main class="game-container">
            <div class="game-board" id="gameBoard"></div>

            <div class="keyboard" id="keyboard">
                <!-- Generated by JS -->
            </div>
        </main>

        <div class="game-status" id="gameStatus"></div>

        <!-- Settings Modal -->
        <div class="modal" id="settingsModal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2>Game Configuration</h2>
                    <button class="modal-close" id="settingsClose">&times;</button>
                </div>
                <div class="modal-body">
                    <div class="setting-item">
                        <label>Word Length (2-10)</label>
                        <div class="range-control">
                            <input type="range" id="wordLength" min="2" max="10" value="5" oninput="this.nextElementSibling.value = this.value">
                            <output>5</output>
                        </div>
                    </div>
                    <div class="setting-item">
                        <label>Max Guesses (1-20)</label>
                        <div class="range-control">
                            <input type="range" id="maxGuesses" min="1" max="20" value="6" oninput="this.nextElementSibling.value = this.value">
                            <output>6</output>
                        </div>
                    </div>
                    <div class="setting-item">
                        <label>Feedback Mode</label>
                        <select id="feedbackMode" class="select-control">
                            <option value="standard">Three-State (Standard)</option>
                            <option value="binary">Binary (Hard Mode)</option>
                        </select>
                    </div>
                    <div class="setting-item">
                        <div class="checkbox-control">
                            <input type="checkbox" id="showDistances">
                            <label for="showDistances">Show Position Distances (Yellow Tiles)</label>
                        </div>
                    </div>
                    <button class="btn btn-primary btn-full" id="startGameBtn">Start Game</button>
                </div>
            </div>
        </div>
    </div>
    <script src="/static/app.js"></script>
</body>
</html>
|}

let () =
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router [
       Dream.get  "/"              index_handler;
       Dream.post "/api/new-game"  new_game_handler;
       Dream.post "/api/guess"     guess_handler;
       Dream.post "/api/hint"      hint_handler;
       Dream.get  "/api/state"     state_handler;
       Dream.get  "/static/**"     (Dream.static "ui/static");
     ]
