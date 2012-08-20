### About
`BESC` is a [StatsD](http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/) client library for Erlang.

Counter _increments_ and _timings_ are collected first and get dispatched every 100 units or on timeout.


### Installation

Add `besc` to your project of choice via [rebar](https://github.com/basho/rebar):

```erlang
% rebar.config
{deps, [
    % Batched Erlang StatsD Client.
    {besc, "",
        {git, "git@github.com:wooga/besc.git",
        {tag, "2fb98078fe76e658c1e1984371fbaca8168e847f"}}}
]}
```

The default configuration points to a StatsD server at `127.0.0.1` listening on port `3344` this can be changed however:
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

You'll find an overview of timings and counters on [Flickr](http://code.flickr.com/blog/2008/10/27/counting-timing/).

1. `besc:inc(Key, By, Rate)` increments a counter, where the fields are:
  * `Key` - A key describing what is being counted, interpreted as a string;
  * `By` - The amount by which to increment the counter,
  * `Rate` - The [sample rate](https://en.wikipedia.org/wiki/Sampling_rate)

2. `besc:dec(Key, By, Rate)` the opposite of inc, decrements a counter. Fields are the same as with `inc`,
3. `besc:time(Key, Value, Rate)` measure how long a task took. Fields still the same, except that `By` is labeled `Value` and reflects the task's duration in miliseconds.


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


### License
This project is licensed under the FreeBSD License. A copy of the license can be found in the repository.
