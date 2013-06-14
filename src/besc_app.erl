-module (besc_app).
-compile ([export_all]).

-behaviour (application).
-export ([start/2, stop/1]).

-behaviour (supervisor_bridge).
-export ([init/1, terminate/2]).


% Build a simple child spec.
-define (child_spec (Id, Module, Args),
    {Id, _MFA = {Module, start_link, Args},
        _RestartType = permanent,
        _ShutdownTimeout = 5000,
        _Type = worker,
        _Modules = [Module]
    }).

% Build a simple supervisor spec around a list of children.
-define (sup_spec (Children),
    {ok, {{
        _Strategy = one_for_one,
        _MaxRestarts = 5,
        _RestartTimeframe = 10},
        Children
    }}).


% Application callback.
% Invoked by the application master upon starting the sharder.
start(_StartType, _StartArgs) ->
    Host = readenv(host, "127.0.0.1"),
    Port = readenv(port, 3344),
    supervisor_bridge:start_link(?MODULE, [Host, Port]).


% Either obtain a param from the environment or return the default.
readenv(Param, Default) ->
    case application:get_env(besc, Param) of
        {ok, Value} -> Value;
        _           -> Default
    end.


% Application callback.
% Invoked after the application has stopped.
% State is the return value of Module:prep_stop/1, if such a function exists.
% Otherwise State is taken from the return value of Module:start/2.
stop(_State) ->
    stopped.


% Supervisor bridge callback.
% Invoked on bringing up the supervision tree, starts elli then idles.
init([Host, Port]) ->
    % Start the client server accepting increments and timings.
    {ok, Pid} = besc:start_link(Host, Port),
    {ok, Pid, _State = Pid}.


% Supervisor bridge callback.
% Called by the supervisor_bridge when it is about to terminate.
terminate(_Reason, Pid) ->
    erlang:exit(Pid, normal).
