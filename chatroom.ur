structure GH = Github.Make(struct
    open Github_app_config
    val https = False
    val onLogin =
     fn _ =>
        (* redirect (url (main ())) *)
        (* can't reference the function by name as it's defined below *)
        redirect (bless "/main")
end)

fun authorize () = GH.authorize

and logout () =
    GH.logout;
    redirect (url (github ()))

and github () =
    someone <- GH.whoami;
    let
        val action = case someone of
                         None => authorize
                       | Some x => logout
        val title = case someone of
                        None => "Log in with GitHub"
                      | Some x => "Sign out " ^ x
    in
        return (Def.page "Urc Authentication" Def.nohdr Def.noload <xml>
          <h1>urc</h1>
          <form>
            <div>
              <submit value={title} action={action}/>
            </div>
          </form>
        </xml>)
    end

val userHeader =
    some <- GH.whoami;
    case some of
        None => redirect (url (github ()))
      | Some u =>
        let
            fun goAdmin _ = redirect (bless "/admin")

            val header =
                <xml>
                  <form>
                    <div>
                      <submit value={"Sign out " ^ u} action={logout}/>
                    </div>
                  </form>
                </xml>

            val adminHeader =
                <xml>
                  <form>
                    <div>
                      <submit value={"Admin"} action={goAdmin}/>
                    </div>
                  </form>
                  <form>
                    <div>
                      <submit value={"Sign out " ^ u} action={logout}/>
                    </div>
                  </form>
                </xml>
        in
            return {User = u, Header = (if u = "proger" then adminHeader else header)}
        end


structure Admin = Crud.Make(struct
    con key = #Login
    val tab = GH.users

    val title = "Authenticated Users"

    val everything = {
        Login = Crud.string "Login",
        AvatarUrl = Crud.string "Avatar URL",
        Nam = Crud.option_string "Name",
        Company = Crud.option_string "Company",
        Blog = Crud.option_string "Blog",
        Location = Crud.option_string "Location",
        Email = Crud.option_string "Email",
        Hireable = Crud.option_bool "Hireable",
        Bio = Crud.option_string "Bio",
        LastUpdated = Crud.time "Last Updated"
    }

    val defpage = fn t b => Def.page t Def.nohdr Def.noload b
    val hdrpage = fn t h b => Def.page t h Def.noload b

    type task_type = {}
    val runTask = fn _ username => redirect (bless ("https://github.com/" ^ username))
    val taskTitle = fn _ => "[Visit]"
    val allTasks = (Cons ((), Nil))

    val header =
        { User = _, Header = hdr } <- userHeader;
        return hdr
end)

val admin = Admin.main

con messagerec = [Author = string, Timestamp = time, Message = string]

table messages : messagerec

open Pubsub.Topic(struct type message = $(messagerec) end)

fun publish' (m : message) : transaction unit =
    Db.put messages m;
    publish m;
    return ()

fun format (m: message) =
    <xml><div><pre>{[m.Timestamp]}</pre> {[m.Author]}: {[m.Message]}</div></xml>

fun prefetch () =
    queryX (SELECT * FROM messages ORDER BY messages.Timestamp DESC)
           (fn row => format row.Messages)

fun main () : transaction page =
    {User = user, Header = hdr} <- userHeader;

    textId <- fresh;
    text <- source "";

    init <- prefetch ();
    ch <- subscribe;
    rest <- source <xml/>;
    received <- source [];

    let
        fun reset () : transaction unit =
            set text "";
            giveFocus textId;
            return ()

        and listen () =
            s <- recv ch;
            xs <- get received;
            set received (s :: xs);
            set rest (List.foldr join <xml/> (List.mp format (s :: xs)));
            listen ()

        and onload () =
            _ <- reset ();
            listen ()

        and submit () : transaction unit =
            message <- get text;
            time <- now;
            rpc (publish' {Author = user, Timestamp = time, Message = message});
            _ <- reset ();
            return ()
    in
        return (Def.page "Urc" hdr (onload ()) <xml>
          <section>
            <h2>chatroom</h2>

            <div>
              <ctextbox id={textId} source={text} />
              <button value="Send" onclick={fn _ => submit ()} /><br/>
            </div>
          </section>

          <section>
            <dyn signal={signal rest} />
            {init}
          </section>
        </xml>)
    end
