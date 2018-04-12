con colMeta = fn (db :: Type, widget :: Type) =>
                 {Nam : string,
                  Show : db -> xbody,
                  Widget : nm :: Name -> xml form [] [nm = widget],
                  WidgetPopulated : nm :: Name -> db -> xml form [] [nm = widget],
                  Parse : widget -> db,
                  Inject : sql_injectable db}
con colsMeta = fn cols => $(map colMeta cols)

fun default [t] (sh : show t) (rd : read t) (inj : sql_injectable t)
            name : colMeta (t, string) =
    {Nam = name,
     Show = txt,
     Widget = fn [nm :: Name] => <xml><textbox{nm}/></xml>,
     WidgetPopulated = fn [nm :: Name] n =>
                          <xml><textbox{nm} value={show n}/></xml>,
     Parse = readError,
     Inject = _}

val int = default
val float : string -> colMeta (float, string) = default
val string = default
val option_string : string -> colMeta (option string, string) = default
val time : string -> colMeta (time, string) = default

fun bool name : colMeta (bool, bool) =
    {Nam = name,
     Show = txt,
     Widget = fn [nm :: Name] => <xml><checkbox{nm}/></xml>,
     WidgetPopulated = fn [nm :: Name] b =>
                          <xml><checkbox{nm} checked={b}/></xml>,
     Parse = fn x => x,
     Inject = _}

fun option_bool name : colMeta (option bool, bool) =
    {Nam = name,
     Show = txt,
     Widget = fn [nm :: Name] => <xml><checkbox{nm}/></xml>,
     WidgetPopulated = fn [nm :: Name] b =>
                          case b of
                              None => <xml><checkbox{nm} checked={False} /></xml>
                            | Some b => <xml><checkbox{nm} checked={b}/></xml>,
     Parse = fn x => Some x,
     Inject = _}


functor Make(M : sig
                 con cols :: {(Type * Type)}

                 type key_type
                 con key :: Name

                 constraint [key] ~ cols

                 val fl : folder ([key = (key_type, key_type)] ++ cols)

                 table tab : ([key = key_type] ++ map fst cols)

                 val title : string

                 val prim_show : show key_type
                 val prim_sql_injectable : sql_injectable key_type

                 val everything : colsMeta ([key = (key_type, key_type)] ++ cols)

                 val hdrpage : string -> xbody -> xbody -> page
                 val defpage : string -> xbody -> page

                 type task_type
                 val runTask : task_type -> key_type -> transaction page
                 val taskTitle : task_type -> string
                 val allTasks : list task_type

                 val header : transaction xbody
             end) = struct

    val tab = M.tab
    type key_type = M.key_type
    con key = M.key

    val everything = M.everything
    con everything = [key = (key_type, key_type)] ++ M.cols

    val defpage = M.defpage M.title

    fun commands (id: key_type) : xbody =
        let
            val mk = fn t => <xml><a link={M.runTask t id}>{[M.taskTitle t]}</a></xml>
        in
            <xml>
              {List.mapX mk M.allTasks}
              <a link={upd id}>[Update]</a>
              <a link={confirm_delete id}>[Delete]</a>
            </xml>
        end

    and list () =
        rows <- queryX (SELECT * FROM tab AS T)
                       (fn (fs : {T : $(map fst everything)}) => <xml>
                         <tr>
                           {@mapX2 [fst] [colMeta] [tr]
                             (fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] v col => <xml>
                               <td>{col.Show v}</td>
                             </xml>)
                             M.fl fs.T everything}
                           <td>
                             {commands fs.T.key}
                           </td>
                         </tr>
                       </xml>);
        return <xml>
          <table>
            <tr>
              {@mapX [colMeta] [tr]
                (fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] col => <xml>
                  <th>{cdata col.Nam}</th>
                </xml>)
                M.fl everything}
              <th>Actions</th>
            </tr>
            {rows}
          </table>


          <section>
            <h3>Create</h3>
            {createForm create}
          </section>
        </xml>

    and createForm action =
        <xml>
          <form>
            <fieldset>
              {@foldR [colMeta] [fn cols => xml form [] (map snd cols)]
                (fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] (col : colMeta t) acc =>
                    <xml>
                      <div><label>{cdata col.Nam}</label> {col.Widget [nm]}</div>
                      {useMore acc}
                    </xml>)
                <xml/>
                M.fl everything}

              <submit action={action}/>
            </fieldset>
          </form>
        </xml>

    and updateForm fs action =
        <xml>
          <form>
            {@foldR2 [fst] [colMeta] [fn cols => xml form [] (map snd cols)]
              (fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] v (col : colMeta t)
                               (acc : xml form [] (map snd rest)) =>
                  <xml>
                    <div><label>{cdata col.Nam}</label> {col.WidgetPopulated [nm] v}</div>
                    {useMore acc}
                  </xml>)
              <xml/>
              M.fl fs everything}

            <submit action={action}/>
          </form>
        </xml>

    and create (inputs : $(map snd everything)) =
        dml (insert tab
                    (@foldR2 [snd] [colMeta]
                      [fn cols => $(map (fn t => sql_exp [] [] [] t.1) cols)]
                      (fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] =>
                       fn input col acc => acc ++ {nm = @sql_inject col.Inject (col.Parse input)})
                      {} M.fl inputs everything));
        main ()

    and upd (id : key_type) : transaction page =
        let
            fun save (inputs : $(map snd everything)) =
                dml (update [map fst everything]
                            (@foldR2 [snd] [colMeta]
                              [fn cols => $(map (fn t => sql_exp [T = map fst everything] [] [] t.1) cols)]
                              (fn [nm :: Name] [t ::_] [rest ::_] [[nm] ~ rest] =>
                               fn input col acc => acc ++ {nm =
                                                           @sql_inject col.Inject (col.Parse input)})
                              {} M.fl inputs everything)
                            tab (sql_binary sql_eq (sql_field [#T] [key]) (sql_inject id)));
                main ()
        in
            fso <- oneOrNoRows (SELECT tab.{{map fst everything}} FROM tab WHERE tab.{key} = {[id]});
            case fso : (Basis.option {Tab : $(map fst everything)}) of
                None => return (defpage <xml>Not found!</xml>)
              | Some fs => return (defpage (updateForm fs.Tab save))
        end

    and confirm_delete (id : key_type) : transaction page =
        let
            fun delete () =
                dml (Basis.delete tab (sql_binary sql_eq (sql_field [#T] [key]) (sql_inject id)));
                main ()
        in
            return (defpage <xml>
              <p>Are you sure you want to delete ID #{[id]}?</p>
              
              <form><submit action={delete} value="Delete"/></form>
            </xml>)
        end

    and main () : transaction page =
        header <- M.header;
        ls <- list ();
        return (M.hdrpage M.title header <xml>
          <section>
            <h1>{cdata M.title}</h1>

            {ls}
          </section>
        </xml>)
end
