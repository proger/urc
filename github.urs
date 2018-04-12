
type profile = { Login : string,
                 AvatarUrl : string,
                 Nam : option string,
                 Company : option string,
                 Blog : option string,
                 Location : option string,
                 Email : option string,
                 Hireable : option bool,
                 Bio : option string }

signature S = sig
    val client_id : string
    val client_secret : string
    val https : bool
    val onLogin : profile -> transaction page
end

functor Make(M : S) : sig

    table users : { Login : string,
                    AvatarUrl : string,
                    Nam : option string,
                    Company : option string,
                    Blog : option string,
                    Location : option string,
                    Email : option string,
                    Hireable : option bool,
                    Bio : option string,
                    LastUpdated : time }
      PRIMARY KEY Login

    (* con users_hidden_constraints = _ *)
    constraint [Pkey = [Login]] ~ users_hidden_constraints

    val authorize : transaction page
    val whoami : transaction (option string)
    val loadProfile : string -> transaction profile
    val logout : transaction unit
end
