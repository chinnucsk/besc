% Size of each message bucket to dispatch.
-define (BUCKET_SIZE, 2500).

% Miliseconds to wait before auto-dispatching a bucket.
-define (BUCKET_TIMEOUT, 250).


% Key of a metric to measure.
-type besc_key() :: string().

% Type by which to increment or gauge a key.
-type besc_inct() :: pos_integer().

% Rate by which a metric should be measured.
-type besc_rate() :: float().

% Type or a remote StatsD host.
-type besc_host() :: inet:ip_address() | inet:hostname().

% Port number type for the host.
-type besc_port() :: inet:port_number().

% State kept by the main loop.
-type besc_state() :: {gen_udp:socket(), besc_host(), besc_port()}.

% Bucket size.
-type besc_bucksiz() :: 0..?BUCKET_SIZE.

% Tag, that is type, of a message.
-type besc_msgtype() :: inc | dec | time.

% Single internal message as understood by besc.
-type besc_msg() :: {besc_msgtype(), besc_key(), besc_inct(), besc_rate()}.

% A bucket is a simple list of messages.
-type besc_bucket() :: [besc_msg()].

% Alias no_return() to signal exceptions may be thrown.
-type besc_throw() :: no_return().


% Constructor for values of type besc_msg().
-define (bescMsgT(Type, Key, IncByOrValue, Rate),
    {Type, Key, IncByOrValue, Rate}).

% Constructor for values of type besc_state().
-define (bescStateT(Socket, Host, Port),
    {Socket, Host, Port}).
