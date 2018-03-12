style page

con msgrec :: {Type} = [Author = string, Timestamp = time, Message = string]

con msg :: Type = $(msgrec)

table message : msgrec

table subscription : { Client : client, Channel : channel msg }

fun easy_insert [fields] [uniques] (injs : $(map sql_injectable fields)) (fl : folder fields)
    (tab : sql_table fields uniques) (fs : $fields) =
    dml (insert tab (@Top.map2 [sql_injectable] [fn s => s] [sql_exp [] [] []]
                     (fn [t] => @sql_inject)
                     fl injs fs))

fun publish (m : msg) : transaction unit =
    client <- self;
    easy_insert message m;
    queryI (SELECT subscription.Channel FROM subscription (* WHERE subscription.Client <> {[client]} *))
           (fn r => send r.Subscription.Channel m);
    return ()

fun subscribe () =
    client <- self;
    ro <- oneOrNoRows (SELECT subscription.Channel FROM subscription WHERE subscription.Client = {[client]});
    case ro of
        None =>
        ch <- channel;
        easy_insert subscription { Client = client, Channel = ch };
        return ch
      | Some r =>
        return r.Subscription.Channel

fun prefetch () =
    queryX (SELECT * FROM message ORDER BY message.Timestamp DESC)
           (fn row => <xml>
             <div>{[row.Message.Author]}: {[row.Message.Message]}</div>
           </xml>)

fun main () : transaction page =
    textId <- fresh;
    authorId <- fresh;
    text <- source "";
    author <- source (show authorId);

    init <- prefetch ();
    ch <- subscribe ();
    rest <- source <xml/>;
    received <- source [];

    let
        fun reset () : transaction unit =
            set text "";
            author' <- get author;
            case author' of
                "" => giveFocus authorId
              | _  => giveFocus textId;
                return ()

        and onload () =
            let
                fun listen () =
                    s <- recv ch;
                    xs <- get received;
                    set received (s :: xs);
                    set rest (List.foldr join <xml/> (List.mp (fn s => <xml><div>{[s.Author]}: {[s.Message]}</div></xml>) (s :: xs)));
                    listen ()
            in
                _ <- reset ();
                listen ()
            end

        and submit () : transaction unit =
            a <- get author;
            message <- get text;
            time <- now;
            rpc (publish {Author = a, Timestamp = time, Message = message});
            _ <- reset ();
            return ()
    in
        return <xml>
          <head>
            <title>pubsub</title>
            <link rel="stylesheet" type="text/css" href="/style.css" />
          </head>
          <body onload={onload ()}>
            <div class={page}>
              <h2>pubsub</h2>

              <div>
                <ctextbox id={authorId} source={author} />
                <ctextbox id={textId} source={text} />
                <button value="Send" onclick={fn _ => submit ()} /><br/>
              </div>

              <dyn signal={signal rest} />
              {init}

            </div>
          </body>
        </xml>
    end
