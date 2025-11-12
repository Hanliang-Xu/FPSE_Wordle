(* main.ml — minimal Dream demo *)

(* Start a Dream web server that responds "Hello, Dream!" on the home page *)
let () =
  Dream.run                             (* Start the Dream server *)
  @@ Dream.logger                       (* Log incoming requests *)
  @@ Dream.router [                     (* Define routes *)
       Dream.get "/" (fun _ ->
         Dream.html "<h1>Hello, Dream!</h1><p>Your setup works ✅</p>");
     ]
