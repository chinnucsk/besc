### About
`BESC` is a [StatsD](http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/) client for Erlang.

Counter increments and timings are collected first and get dispatched every 2500 metrics or on timeout.

### Installation

Add `besc` to your project of choice via [rebar](https://github.com/basho/rebar):

```erlang
% rebar.config
{deps, [
    % Batched Erlang StatsD Client.
    {besc, "",
        {git, "git@github.com:wooga/besc.git",
        {branch, "stable"}}}
]}
```

The default configuration points to a StatsD server at `127.0.0.1` listening on port `3344`, this can be changed however:
* Override the configuration using `application:set_env` and friends:

    ```erlang
    application:set_env(besc, host, "10.20.30.40"),
    application:set_env(besc, port, 1259),
    application:start(besc).
    ```

* When building your own supervision tree:
    ```erlang
    besc:start_link(Hostname, PortNum)
    ```
* Or the custom start entirely:
    ```erlang
    besc:start(Hostname, PortNum).
    ```

### Usage

Find an overview of the concept of timings and counters on the [Flickr Blog](http://code.flickr.com/blog/2008/10/27/counting-timing/).

1. `besc:inc(Key, By, Rate)` increments a counter, where the fields are:
  * `Key` - A key describing what is being counted, interpreted as a string
  * `By` - The amount by which to increment the counter
  * `Rate` - The [sampling rate](https://en.wikipedia.org/wiki/Sampling_rate)

2. `besc:dec(Key, By, Rate)` the opposite of inc, decrements a counter. Parameters are the same as with `inc`
3. `besc:time(Key, Value, Rate)` measure how long a task took. Parameters are the same, except for `By`, which is labeled `Value` and reflects the task's duration _in miliseconds_


### Examples

```erlang
1> application:start(besc).
ok
2> {Duration, _} = timer:tc(timer, sleep, [random:uniform(100)]).
{46058,ok}
3> besc:time("sleep_duration", Duration, 0.75).
ok
4> besc:inc("noops", 1, 1.0).
ok
```
Received and subsequently interpreted on the server's side:
```
sleep_duration:46055|ms|@0.750000
noops:1|c|@1.000000
```


### License
This project is licensed under the FreeBSD License. A copy of the license can be found in the repository.
