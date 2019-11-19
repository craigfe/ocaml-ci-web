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

let v_of_src src =
  let node_base = Docker.pull ~schedule:weekly "node:alpine" in
  let img = project node_base src in
  Current.all [ lint img; build img ]

let v_of_repo repo () = Git.Local.head_commit repo |> v_of_src

let v_of_app app () =
  let open Current_github in
  let it = Current.list_iter in
  App.installations app
  |> it ~pp:Installation.pp @@ fun installation ->
     Installation.repositories installation
     |> it ~pp:Api.Repo.pp @@ fun repo ->
        Api.Repo.ci_refs repo
        |> it ~pp:Api.Commit.pp @@ fun head ->
           Git.fetch (Current.map Api.Commit.id head) |> v_of_src
