signature S = sig
    val authorize_url : url
    val access_token_url : url

    val client_id : string
    val client_secret : string

    val onToken : string -> transaction page
end

functor Make(M : S) : sig
    val authorize : transaction page
end
