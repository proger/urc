
signature S = sig
    type message
end

functor Topic(M: S) = struct
    open M

    table subscriptions : { Client : client, Channel : channel message }

    fun mapChannelsI (f : channel message -> transaction unit) : transaction unit =
        queryI (SELECT subscriptions.Channel FROM subscriptions)
               (fn r => f r.Subscriptions.Channel)

    fun publish (m : message) : transaction unit =
        mapChannelsI (fn ch => send ch m)

    val subscribe : transaction (channel message) =
        client <- self;
        ro <- oneOrNoRows (SELECT subscriptions.Channel FROM subscriptions
                           WHERE subscriptions.Client = {[client]});
        case ro of
            None =>
            ch <- channel;
            Db.put subscriptions { Client = client, Channel = ch };
            return ch
          | Some r =>
            return r.Subscriptions.Channel
end
