-module (besc).
-compile (export_all).


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
    % Let the process have its own unique random numbers,
    random:seed(erlang:now()),

    % Obtain a UDP sockets for sending packages to the server,
    {ok, Socket} = gen_udp:open(0),
    do_loop(_State = {Socket, Host, Port}).


% Sample the message, either sending or discarding it.
do_loop(State = {Socket, Host, Port}) ->
    receive
        {_, _, _, Rate} = Message ->
            case Rate == 1.0 orelse random:uniform() =< Rate of
                true ->
                    StrMsg = render_message(Message),
                    gen_udp:send(Socket, Host, Port, StrMsg);
                false -> ignored
            end,
            do_loop(State);

        % Ignore any other messages.
        _ -> do_loop(State)
    after
        % Allow code reload at arbitrary points.
        1000 -> do_loop(State)
    end.


% Format a message into a statsd-compliant string.

render_message({inc, Key, By, Rate}) ->
    io_lib:format("~s:~B|c|@~f", [Key, By, Rate]);

render_message({dec, Key, By, Rate}) ->
    io_lib:format("~s:-~B|c|@~f", [Key, By, Rate]);

render_message({time, Key, Value, Rate}) ->
    io_lib:format("~s:~B|ms|@~f", [Key, Value, Rate]).
