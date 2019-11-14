module Git = Current_git
module Docker = Current_docker.Default

let () = Logging.init ~level:Logs.Debug ()

let main config mode repo =
  let repo = Git.Local.v (Fpath.v repo) in
  let engine = Current.Engine.create ~config (Pipeline.v ~repo) in
  Logging.run
    (Lwt.choose [ Current.Engine.thread engine; Current_web.run ~mode engine ])

(* Command-line parsing *)

open Cmdliner

let repo =
  Arg.value
  @@ Arg.pos 0 Arg.dir (Sys.getcwd ())
  @@ Arg.info ~doc:"The directory containing the .git subdirectory." ~docv:"DIR"
       []

let cmd =
  let doc = "Build the head commit of a local Git repository using Docker." in
  ( Term.(const main $ Current.Config.cmdliner $ Current_web.cmdliner $ repo),
    Term.info "build_matrix" ~doc )

let () = Term.(exit @@ eval cmd)
