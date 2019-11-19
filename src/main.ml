module Git = Current_git
module Docker = Current_docker.Default

let () = Logging.init ~level:Logs.Debug ()

let main config mode src =
  let pipeline, webhooks =
    match src with
    | `Path path ->
        let repo = Git.Local.v (Fpath.v path) in
        (Pipeline.v_of_repo repo, [])
    | `App app ->
        (Pipeline.v_of_app app, [ ("github", Current_github.input_webhook) ])
  in
  let engine = Current.Engine.create ~config pipeline in
  Logging.run
    (Lwt.choose
       [ Current.Engine.thread engine; Current_web.run ~mode ~webhooks engine ])

(* Command-line parsing *)

open Cmdliner

let repo_path =
  Arg.value
  @@ Arg.pos 0 Arg.dir (Sys.getcwd ())
  @@ Arg.info ~doc:"The directory containing the .git subdirectory."
       ~docv:"DIR" []

let cmds =
  Term.
    [
      ( const main $ Current.Config.cmdliner $ Current_web.cmdliner
        $ app (pure (fun p -> `Path p)) repo_path,
        info "local" );
      ( const main $ Current.Config.cmdliner $ Current_web.cmdliner
        $ app (pure (fun a -> `App a)) Current_github.App.cmdliner,
        info "app" );
    ]

let default =
  let doc = "Run ocaml-ci-web pipeline on a set of projects" in
  let exits = Term.default_exits in
  let man = [] in
  Term.
    (ret (const (`Help (`Auto, None))), info "ocaml-ci-web" ~doc ~exits ~man)

let () = Term.(exit @@ eval_choice default cmds)
