# How to run reliability tests

```
cd tests/reliability
bundle exec ruby reliability_test.rb
```

You can adjust some parameters of the test in the `config.rb`.

JOB_FETCHER can be set to one of these values: `semi`, `reliable`, `basic`

You need to have redis server running on default HTTP port `6379`. To use other HTTP port, you can define
`REDIS_URL` environment varible with the port you need(example: `REDIS_URL="redis://localhost:9999"`).


## How it works

This tool spawns configured number of Sidekiq workers and when the amount of processed jobs is about half of origin
number it will kill all the workers with `kill -9` and then it will spawn new workers again until all the jobs are processed. To track the process and counters we use Redis keys/counters.

# How to run interruption tests

```
cd tests/interruption

# Verify "KILL" signal
bundle exec ruby test_kill_signal.rb

# Verify "TERM" signal
bundle exec ruby test_term_signal.rb
```

It requires Redis to be running on 6379 port.

## How it works

It spawns Sidekiq workers then creates a job that will kill itself after a moment. The  reliable fetcher will bring it back. The purpose is to verify that job is run no more then allowed number of times.
