-module (besc).
-compile ([export_all]).
-include ("besc.hrl").


% Convenience starter using the defaults.
start() ->
    application:start(besc).

% Convenience starter using the specified settings.
start(Host, Port) ->
    application:set_env(besc, host, Host),
    application:set_env(besc, port, Port),
    application:start(besc).


-spec inc(besc_key(), besc_inct(), besc_rate()) -> ok.
% Request to increment the specified `Key` by the amount of `By`
% at the given sample rate `Rate`.
inc(Key, By, Rate) ->
    whereis(?MODULE) ! ?bescMsgT(inc, Key, By, Rate),
    ok.


-spec dec(besc_key(), besc_inct(), besc_rate()) -> ok.
% Request to decrement the specified `Key` by the amount of `By`
% at the given sample rate `Rate`.
dec(Key, By, Rate) ->
    whereis(?MODULE) ! ?bescMsgT(dec, Key, By, Rate),
    ok.


-spec time(besc_key(), besc_inct(), besc_rate()) -> ok.
% Request to time some action named by `Key` by `Value`
% at the given sample rate `Rate`.
time(Key, Value, Rate) ->
    whereis(?MODULE) ! ?bescMsgT(time, Key, Value, Rate),
    ok.


-spec start_link(besc_host(), besc_port()) -> {ok, pid()}.
% Non-callback starter invoked by `besc_app`.
start_link(Host, Port) ->
    Pid = spawn_link(?MODULE, loop, [Host, Port]),
    register(besc, Pid),
    {ok, Pid}.


-spec loop(besc_host(), besc_port()) -> no_return() | besc_throw().
% Initialize the `besc` server.
loop(Host, Port) ->
    % Obtain a UDP sockets for sending packages to the server,
    {ok, Socket} = gen_udp:open(0),
    do_loop(?bescStateT(Socket, Host, Port), 0, []).


-spec do_loop(besc_state(), besc_bucksiz(), besc_bucket()) ->
    no_return() | besc_throw().
% Full bucket, handle in another process & continue emptied.
do_loop(State, ?BUCKET_SIZE, Bucket) ->
    spawn(?MODULE, dispatch, [State, Bucket]),
    do_loop(State, 0, []);

do_loop(State, BucketSize, Bucket) ->
    receive
        ?bescMsgT(_,_,_,_) = Message ->
            do_loop(State, BucketSize + 1, [Message|Bucket]);

        % Ignore any other messages.
        _ -> do_loop(State, BucketSize, Bucket)
    after
        % Pretend the bucket is full after the timeout.
        ?BUCKET_TIMEOUT -> ?MODULE:do_loop(State, ?BUCKET_SIZE, Bucket)
    end.


-spec dispatch(besc_state(), besc_bucket()) -> done | besc_throw().
dispatch(State, Bucket) ->
    % Let the process have its own unique random numbers,
    _ = random:seed(erlang:now()),
    do_dispatch(State, Bucket).

% Done with all messages.
do_dispatch(_, []) -> done;

% Sample rate of 1.0, send packet unquestioned.
do_dispatch(State, [Message = ?bescMsgT(_,_,_, 1.0) | Bucket]) ->
    ok = udp_send(State, Message),
    do_dispatch(State, Bucket);

% Apply the sampling rate to all other messages.
do_dispatch(State, [Message = ?bescMsgT(_,_,_, Rate) | Bucket]) ->
    Rand = random:uniform(),
    ok = Rand =< Rate andalso udp_send(State, Message),
    do_dispatch(State, Bucket).


-spec udp_send(besc_state(), besc_msg()) ->
    ok | {error, not_owner | inet:posix()}.
% Render and send the message via UDP to the StasD server.
udp_send(?bescStateT(Socket, Host, Port), Message) ->
    gen_udp:send(Socket, Host, Port, render_message(Message)).


-spec render_message(besc_msg()) -> io_lib:chars().
% Format a message into a StatsD-compliant string.
render_message({inc, Key, By, Rate}) ->
    io_lib:format("~s:~B|c|@~f", [Key, By, Rate]);

render_message({dec, Key, By, Rate}) ->
    io_lib:format("~s:-~B|c|@~f", [Key, By, Rate]);

render_message({time, Key, Value, Rate}) ->
    io_lib:format("~s:~B|ms|@~f", [Key, Value, Rate]).
