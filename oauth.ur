open Urls

signature S = sig
    val authorize_url : url
    val access_token_url : url

    val client_id : string
    val client_secret : string

    val onToken : string -> transaction page
end

table states : { State : int, Expires : time }
  PRIMARY KEY State

(* task periodic 300 = fn () => *)
(*                        dml (DELETE FROM states WHERE Expires < CURRENT_TIMESTAMP) *)


datatype access_response =
         Token of string
       | Error of string


fun parse1 s code state =
    case String.split s #"=" of
        None =>
        (case code of
             None => error <xml>No code in OAuth authorization response</xml>
           | Some code =>
             case state of
                 None => error <xml>No state in OAuth authorization response</xml>
               | Some state =>
                 case read state of
                     None => error <xml>Noninteger state in OAuth authorization response</xml>
                   | Some state => (code, state))
      | Some (param, s) =>
        let
            val (value, rest) =
                case String.split s #"&" of
                    None => (s, "")
                  | Some p => p
        in
            parse1 rest
            (if param = "code" then Some value else code)
            (if param = "state" then Some value else state)
        end

fun parse2 s token =
    case String.split s #"=" of
        None =>
        (case token of
             None => error <xml>No token in OAuth access response</xml>
           | Some token => token)
      | Some (param, s) =>
        let
            val (value, rest) =
                case String.split s #"&" of
                    None => (s, "")
                  | Some p => p
        in
            parse2 rest
            (case param of
                 "access_token" => Some (Token (urldecode value))
               | "error_description" => Some (Error (urldecode value))
               | _ => token)
        end

fun assert_show_qs qs =
    case qs of
        None => error <xml>No query string in OAuth authorization response</xml>
      | Some qs => return (show qs)


functor Make(M : S) = struct
    open M

    val authorize =
        let
            fun authorized (qs : option queryString) =
                qs <- assert_show_qs qs;
                (code, state) <- return (parse1 qs None None);

                goodState <- oneRowE1 (SELECT COUNT( * ) > 0
                                       FROM states
                                       WHERE states.State = {[state]});
                if not goodState then
                    error <xml>Bad state in OAuth authorization response</xml>
                else
                    dml (DELETE FROM states WHERE State = {[state]});
                    pb <- WorldFfi.post access_token_url
                                        ("client_id=" ^ urlencode client_id
                                         ^ "&client_secret=" ^ urlencode client_secret
                                         ^ "&code=" ^ urlencode code
                                         ^ "&state=" ^ show state);
                    case parse2 pb None of
                        Error msg => error <xml>OAuth error: {[msg]}</xml>
                      | Token token => onToken token
        in
            state <- rand;
            tm <- now;
            dml (INSERT INTO states(State, Expires) VALUES({[state]}, {[addSeconds tm 300]}));

            debug (show (effectfulUrl authorized));
            redirect (bless (show authorize_url
                             ^ "?client_id=" ^ urlencode client_id
                             ^ "&redirect_uri=" ^ urlencode (show (effectfulUrl authorized))
                             ^ "&state=" ^ show state))
        end
end
