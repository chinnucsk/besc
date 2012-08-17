-module (besc).
-compile (export_all).

-behavior (gen_server).
-export ([
    start_link/2,
    init/1, handle_call/3, handle_cast/2, handle_info/2,
    terminate/2, code_change/3]).


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
    gen_server:cast(?MODULE, {inc, Key, By, Rate}).

% Request to decrement the specified `Key` by the amount of `By`
% at the given sample rate `Rate`.
dec(Key, By, Rate) ->
    gen_server:cast(?MODULE, {dec, Key, By, Rate}).

% Request to time some action named by `Key` by `Value`
% at the given sample rate `Rate`.
time(Key, Value, Rate) ->
    gen_server:cast(?MODULE, {time, Key, Value, Rate}).


% Non-callback starter invoked by `besc_app`.
start_link(Host, Port) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [Host, Port], []).


% Initialize the `besc` server.
init([Host, Port]) ->
    process_flag(trap_exit, true),
    % Let the process have its own unique random numbers,
    random:seed(erlang:now()),

    % Obtain a UDP sockets for sending packages to the server,
    {ok, Socket} = gen_udp:open(0),
    {ok, {Socket, Host, Port}}.


% Sample the message, either sending or discarding it.
handle_cast(Message = {_, _, _, Rate}, State = {Socket, Host, Port}) ->
    case random:uniform() =< Rate of
        true  -> gen_udp:send(Socket, Host, Port, render_message(Message));
        false -> ignored
    end,
    {noreply, State};

% Ignore everything else.
handle_cast(_Message, State) -> {noreply, State}.


% Format a message into a statsd-compliant string.

render_message({inc, Key, By, Rate}) ->
    io_lib:format("~s:~B|c|@~f", [Key, By, Rate]);

render_message({dec, Key, By, Rate}) ->
    io_lib:format("~s:-~B|c|@~f", [Key, By, Rate]);

render_message({time, Key, Value, Rate}) ->
    io_lib:format("~s:~B|ms|@~f", [Key, Value, Rate]).


% Ignore everything else.

handle_call(_Mesage, _From, State) -> {reply, ok, State}.
handle_info(_Info, State) -> {noreply, State}.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
terminate(_Reason, _State) -> terminated.
