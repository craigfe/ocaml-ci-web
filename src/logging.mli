val init : ?level:Logs.level -> unit -> unit

val run :
  (unit, [ `Msg of string ]) result Lwt.t -> (unit, [ `Msg of string ]) result
