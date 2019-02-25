-module(message_router).

-define(SERVER, message_router).

-compile(export_all).

start() ->
    Pid = spawn(message_router, route_messages, [dict:new()]),
    erlang:register(?SERVER, Pid).

stop() ->
    ?SERVER ! shutdown.
    
send_chat_message(Addressee, MessageBody) ->
    ?SERVER ! {send_chat_msg, Addressee, MessageBody}.

register_client(ClientName, PrintFun) ->
    ?SERVER ! {register_client, ClientName, PrintFun}.
    
unregister_client(ClientName) ->
    ?SERVER ! {unregister_client, ClientName}.

route_messages(Clients) ->
    receive
        {send_chat_msg, ClientName, MessageBody} ->
            ?SERVER ! {recv_chat_msg, ClientName, MessageBody},
            route_messages(Clients);
        {recv_chat_msg, ClientName, MessageBody} ->
            case dict:find(ClientName, Clients) of
                {ok, PrintFun} ->
                    PrintFun(MessageBody);
                error ->
                    io:format("Unknown client~n")
            end,
            route_messages(Clients);
        {register_client, ClientName, PrintFun} ->
            route_messages(dict:store(ClientName, PrintFun, Clients));
        {unregister_client, ClientName} ->
            route_messages(dict:erase(ClientName, Clients));
        shutdown ->
            io:format("Shutting down~n");
        Others ->
            io:format("Warning! Received: ~p~n", [Others]),
            route_messages(Clients)
    end.
