open Current.Syntax
module Git = Current_git
module Docker = Current_docker.Default

let dockerfile_project ~base =
  let open Dockerfile in
  from (Docker.Image.hash base)
  @@ run "apk add yarn"
  @@ copy ~src:[ "." ] ~dst:"/src/" ()
  @@ workdir "/src" @@ run "yarn install"

let weekly = Current_cache.Schedule.v ~valid_for:(Duration.of_day 7) ()

(* Pipeline stages *)
let project base src =
  let dockerfile =
    let+ base = base in
    dockerfile_project ~base
  in
  Docker.build ~label:"dependencies" ~pull:false ~dockerfile (`Git src)

let build base =
  Docker.run ~label:"test" base ~args:[ "yarn"; "run"; "build" ]
  |> Current.ignore_value

let lint base =
  Docker.run ~label:"lint" base ~args:[ "yarn"; "run"; "lint" ]
  |> Current.ignore_value

let v ~repo () =
  let src = Git.Local.head_commit repo in
  let node_base = Docker.pull ~schedule:weekly "node:alpine" in
  let img = project node_base src in
  Current.all [ lint img; build img ]
