(** Test suite for UI module *)

open Core
open OUnit2

(** Helper to redirect stdin from a string using pipes and suppress stdout *)
let with_stdin_from_string input f =
  let module U = Caml_unix in
  (* Suppress stdout *)
  let dev_null_fd = U.openfile "/dev/null" [U.O_WRONLY] 0o644 in
  let original_stdout = U.dup U.stdout in
  U.dup2 dev_null_fd U.stdout;
  U.close dev_null_fd;
  Out_channel.flush Out_channel.stdout;
  
  (* Create a pipe for stdin *)
  let (r, w) = U.pipe () in
  (* Write input to pipe *)
  ignore (U.write w (Bytes.of_string input) 0 (String.length input));
  U.close w;
  (* Save original stdin *)
  let original_stdin = U.dup U.stdin in
  (* Redirect stdin from pipe *)
  U.dup2 r U.stdin;
  U.close r;
  (* Flush stdout before redirect *)
  Out_channel.flush Out_channel.stdout;
  let result = f () in
  (* Flush after function *)
  Out_channel.flush Out_channel.stdout;
  (* Restore original stdin *)
  U.dup2 original_stdin U.stdin;
  U.close original_stdin;
  (* Restore original stdout *)
  U.dup2 original_stdout U.stdout;
  U.close original_stdout;
  (* Flush after restore *)
  Out_channel.flush Out_channel.stdout;
  result

(** Test prompt_int with various inputs *)
let test_prompt_int_default _ =
  (* Test default value when input is empty *)
  let result = with_stdin_from_string "\n" (fun () ->
    Lib.Ui.prompt_int ~default:5 ~min:2 ~max:10 "test"
  ) in
  assert_equal 5 result

let test_prompt_int_valid_input _ =
  (* Test valid input *)
  let result = with_stdin_from_string "7\n" (fun () ->
    Lib.Ui.prompt_int ~default:5 ~min:2 ~max:10 "test"
  ) in
  assert_equal 7 result

let test_prompt_int_invalid_then_default _ =
  (* Test invalid input falls back to default *)
  let result = with_stdin_from_string "99\n" (fun () ->
    Lib.Ui.prompt_int ~default:5 ~min:2 ~max:10 "test"
  ) in
  assert_equal 5 result

let test_prompt_int_at_boundaries _ =
  (* Test min and max boundaries *)
  let result_min = with_stdin_from_string "2\n" (fun () ->
    Lib.Ui.prompt_int ~default:5 ~min:2 ~max:10 "test"
  ) in
  assert_equal 2 result_min;
  let result_max = with_stdin_from_string "10\n" (fun () ->
    Lib.Ui.prompt_int ~default:5 ~min:2 ~max:10 "test"
  ) in
  assert_equal 10 result_max

(** Test prompt_bool *)
let test_prompt_bool_yes _ =
  let result = with_stdin_from_string "y\n" (fun () ->
    Lib.Ui.prompt_bool ~default:false "test"
  ) in
  assert_bool "Should return true for 'y'" result

let test_prompt_bool_no _ =
  let result = with_stdin_from_string "n\n" (fun () ->
    Lib.Ui.prompt_bool ~default:true "test"
  ) in
  assert_bool "Should return false for 'n'" (not result)

let test_prompt_bool_default_empty _ =
  let result = with_stdin_from_string "\n" (fun () ->
    Lib.Ui.prompt_bool ~default:true "test"
  ) in
  assert_bool "Should return default for empty input" result

let test_prompt_bool_yes_uppercase _ =
  let result = with_stdin_from_string "YES\n" (fun () ->
    Lib.Ui.prompt_bool ~default:false "test"
  ) in
  assert_bool "Should return true for 'YES'" result

let test_prompt_bool_invalid_then_valid _ =
  (* Test invalid input then valid input *)
  let result = with_stdin_from_string "maybe\ny\n" (fun () ->
    Lib.Ui.prompt_bool ~default:false "test"
  ) in
  assert_bool "Should return true after invalid then valid input" result

(** Test prompt_feedback_granularity *)
let test_prompt_feedback_granularity_default _ =
  let result = with_stdin_from_string "\n" (fun () ->
    Lib.Ui.prompt_feedback_granularity ()
  ) in
  assert_equal Lib.Config.ThreeState result

let test_prompt_feedback_granularity_three_state _ =
  let result = with_stdin_from_string "1\n" (fun () ->
    Lib.Ui.prompt_feedback_granularity ()
  ) in
  assert_equal Lib.Config.ThreeState result

let test_prompt_feedback_granularity_binary _ =
  let result = with_stdin_from_string "2\n" (fun () ->
    Lib.Ui.prompt_feedback_granularity ()
  ) in
  assert_equal Lib.Config.Binary result

let test_prompt_feedback_granularity_invalid_then_default _ =
  let result = with_stdin_from_string "99\n" (fun () ->
    Lib.Ui.prompt_feedback_granularity ()
  ) in
  assert_equal Lib.Config.ThreeState result

(** Test prompt_hint_mode *)
let test_prompt_hint_mode_default _ =
  let result = with_stdin_from_string "\n" (fun () ->
    Lib.Ui.prompt_hint_mode ()
  ) in
  assert_equal 1 result

let test_prompt_hint_mode_one _ =
  let result = with_stdin_from_string "1\n" (fun () ->
    Lib.Ui.prompt_hint_mode ()
  ) in
  assert_equal 1 result

let test_prompt_hint_mode_two _ =
  let result = with_stdin_from_string "2\n" (fun () ->
    Lib.Ui.prompt_hint_mode ()
  ) in
  assert_equal 2 result

let test_prompt_hint_mode_invalid_then_valid _ =
  let result = with_stdin_from_string "99\n2\n" (fun () ->
    Lib.Ui.prompt_hint_mode ()
  ) in
  assert_equal 2 result

(** Test get_config - requires multiple inputs *)
let test_get_config_full _ =
  (* Test full config with all inputs *)
  let result = with_stdin_from_string "5\n6\n1\nn\n" (fun () ->
    Lib.Ui.get_config ()
  ) in
  let word_length, max_guesses, show_hints, feedback_granularity, show_position_distances = result in
  assert_equal 5 word_length;
  assert_equal 6 max_guesses;
  assert_equal false show_hints;
  assert_equal Lib.Config.ThreeState feedback_granularity;
  assert_equal false show_position_distances

let test_get_config_with_defaults _ =
  (* Test with all defaults (empty inputs) *)
  let result = with_stdin_from_string "\n\n\n\n" (fun () ->
    Lib.Ui.get_config ()
  ) in
  let word_length, max_guesses, show_hints, feedback_granularity, show_position_distances = result in
  assert_equal 5 word_length;
  assert_equal 6 max_guesses;
  assert_equal false show_hints;
  assert_equal Lib.Config.ThreeState feedback_granularity;
  assert_equal false show_position_distances

let test_get_config_binary_mode _ =
  (* Test with binary mode *)
  let result = with_stdin_from_string "5\n6\n2\nn\n" (fun () ->
    Lib.Ui.get_config ()
  ) in
  let _, _, _, feedback_granularity, _ = result in
  assert_equal Lib.Config.Binary feedback_granularity

let suite =
  "UI module tests" >::: [
    "prompt_int_default" >:: test_prompt_int_default;
    "prompt_int_valid_input" >:: test_prompt_int_valid_input;
    "prompt_int_invalid_then_default" >:: test_prompt_int_invalid_then_default;
    "prompt_int_at_boundaries" >:: test_prompt_int_at_boundaries;
    "prompt_bool_yes" >:: test_prompt_bool_yes;
    "prompt_bool_no" >:: test_prompt_bool_no;
    "prompt_bool_default_empty" >:: test_prompt_bool_default_empty;
    "prompt_bool_yes_uppercase" >:: test_prompt_bool_yes_uppercase;
    "prompt_bool_invalid_then_valid" >:: test_prompt_bool_invalid_then_valid;
    "prompt_feedback_granularity_default" >:: test_prompt_feedback_granularity_default;
    "prompt_feedback_granularity_three_state" >:: test_prompt_feedback_granularity_three_state;
    "prompt_feedback_granularity_binary" >:: test_prompt_feedback_granularity_binary;
    "prompt_feedback_granularity_invalid_then_default" >:: test_prompt_feedback_granularity_invalid_then_default;
    "prompt_hint_mode_default" >:: test_prompt_hint_mode_default;
    "prompt_hint_mode_one" >:: test_prompt_hint_mode_one;
    "prompt_hint_mode_two" >:: test_prompt_hint_mode_two;
    "prompt_hint_mode_invalid_then_valid" >:: test_prompt_hint_mode_invalid_then_valid;
    "get_config_full" >:: test_get_config_full;
    "get_config_with_defaults" >:: test_get_config_with_defaults;
    "get_config_binary_mode" >:: test_get_config_binary_mode;
  ]

let () = run_test_tt_main suite

