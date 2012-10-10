-module (besc).
-compile (export_all).

% Size of each message bucket to dispatch.
-define (BUCKET_SIZE, 2500).


% Convenience starter using the defaults.
start() ->
    application:start(besc).

% Convenience starter using the specified settings.
start(Host, Port) ->
    application:set_env(besc, host, Host),
    application:set_env(besc, port, Port),
    application:start(besc).


% Request to increment the specified `Key` by the amount of `By`
% at the given sample rate `Rate`.
inc(Key, By, Rate) ->
    ?MODULE ! {inc, Key, By, Rate}.

% Request to decrement the specified `Key` by the amount of `By`
% at the given sample rate `Rate`.
dec(Key, By, Rate) ->
    ?MODULE ! {dec, Key, By, Rate}.

% Request to time some action named by `Key` by `Value`
% at the given sample rate `Rate`.
time(Key, Value, Rate) ->
    ?MODULE ! {time, Key, Value, Rate}.


% Non-callback starter invoked by `besc_app`.
start_link(Host, Port) ->
    Pid = spawn_link(?MODULE, loop, [Host, Port]),
    register(besc, Pid),
    {ok, Pid}.


% Initialize the `besc` server.
loop(Host, Port) ->
    % Obtain a UDP sockets for sending packages to the server,
    {ok, Socket} = gen_udp:open(0),
    do_loop(_State = {Socket, Host, Port}, 0, []).


% Full bucket, handle in another process & continue emptied.
do_loop(State, ?BUCKET_SIZE, Bucket) ->
    spawn(?MODULE, dispatch, [State, Bucket]),
    do_loop(State, 0, []);

do_loop(State, BucketSize, Bucket) ->
    receive
        {_, _, _, _} = Message ->
            do_loop(State, BucketSize + 1, [Message|Bucket]);

        % Ignore any other messages.
        _ -> do_loop(State, BucketSize, Bucket)
    after
        % Pretend the bucket is full.
        250 -> do_loop(State, ?BUCKET_SIZE, Bucket)
    end.

dispatch(State, Bucket) ->
    % Let the process have its own unique random numbers,
    random:seed(erlang:now()),
    do_dispatch(State, Bucket).

do_dispatch(_, []) -> done;
do_dispatch(State = {Socket, Host, Port}, [Message|Bucket]) ->
    {_, _, _, Rate} = Message,
    case Rate == 1.0 orelse random:uniform() =< Rate of
        true ->
            StrMsg = render_message(Message),
            gen_udp:send(Socket, Host, Port, StrMsg);
        false -> ignored
    end,
    do_dispatch(State, Bucket).


% Format a message into a statsd-compliant string.
render_message({inc, Key, By, Rate}) ->
    io_lib:format("~s:~B|c|@~f", [Key, By, Rate]);

render_message({dec, Key, By, Rate}) ->
    io_lib:format("~s:-~B|c|@~f", [Key, By, Rate]);

render_message({time, Key, Value, Rate}) ->
    io_lib:format("~s:~B|ms|@~f", [Key, Value, Rate]).
