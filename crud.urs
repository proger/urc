con colMeta = fn (db :: Type, widget :: Type) =>
                 {Nam : string,
                  Show : db -> xbody,
                  Widget : nm :: Name -> xml form [] [nm = widget],
                  WidgetPopulated : nm :: Name -> db -> xml form [] [nm = widget],
                  Parse : widget -> db,
                  Inject : sql_injectable db}
con colsMeta = fn cols :: {(Type * Type)} => $(map colMeta cols)

val int : string -> colMeta (int, string)
val float : string -> colMeta (float, string)
val string : string -> colMeta (string, string)
val option_string : string -> colMeta (option string, string)
val bool : string -> colMeta (bool, bool)
val option_bool : string -> colMeta (option bool, bool)
val time : string -> colMeta (time, string)



functor Make(M : sig
                 con cols :: {(Type * Type)}

                 type key_type
                 con key :: Name

                 constraint [key] ~ cols

                 val fl : folder ([key = (key_type, key_type)] ++ cols)

                 table tab : ([key = key_type] ++ map fst cols)

                 val title : string

                 (* val defid : key_type *)
                 val prim_show : show key_type
                 val prim_sql_injectable : sql_injectable key_type

                 val everything : colsMeta ([key = (key_type, key_type)] ++ cols)

                 val defpage : string -> xbody -> page
                 val hdrpage : string -> xbody -> xbody -> page

                 type task_type

                 val runTask : task_type -> key_type -> transaction page
                 val taskTitle : task_type -> string
                 val allTasks : list task_type

                 val header : transaction xbody

             end) : sig
    val main : unit -> transaction page
end
