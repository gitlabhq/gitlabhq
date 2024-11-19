gitlab-sidekiq-fetcher
======================

`gitlab-sidekiq-fetcher` is an extension to Sidekiq that adds support for reliable
fetches from Redis.

It's based on https://github.com/TEA-ebook/sidekiq-reliable-fetch.

**IMPORTANT NOTE:** Since version `0.11.0` this gem works only with `sidekiq >= 7` (which introduced Fetch API breaking changes). Please use version `~> 0.10` if you use older version of the `sidekiq` .

**UPGRADE NOTE:** If upgrading from 0.7.0, strongly consider a full deployed step on 0.7.1 before 0.8.0; that fixes a bug in the queue name validation that will hit if sidekiq nodes running 0.7.0 see working queues named by 0.8.0.  See https://gitlab.com/gitlab-org/sidekiq-reliable-fetch/-/merge_requests/22

There are two strategies implemented: [Reliable fetch](http://redis.io/commands/rpoplpush#pattern-reliable-queue) using `rpoplpush` command and
semi-reliable fetch that uses regular `brpop` and `lpush` to pick the job and put it to working queue. The main benefit of "Reliable" strategy is that `rpoplpush` is atomic, eliminating a race condition in which jobs can be lost.
However, it comes at a cost because `rpoplpush` can't watch multiple lists at the same time so we need to iterate over the entire queue list which significantly increases pressure on Redis when there are more than a few queues. The "semi-reliable" strategy is much more reliable than the default Sidekiq fetcher, though. Compared to the reliable fetch strategy, it does not increase pressure on Redis significantly.

### Interruption handling

Sidekiq expects any job to report success or to fail. In the last case, Sidekiq puts `retry_count` counter
into the job and keeps to re-run the job until the counter reached the maximum allowed value. When the job has
not been given a chance to finish its work(to report success or fail), for example, when it was killed forcibly or when the job was requeued, after receiving TERM signal, the standard retry mechanism does not get into the game and the job will be retried indefinitely. This is why Reliable fetcher maintains a special counter `interrupted_count`
which is used to limit the amount of such retries. In both cases, Reliable Fetcher increments counter `interrupted_count` and rejects the job from running again when the counter exceeds `max_retries_after_interruption` times (default: 3 times).
Such a job will be put to `interrupted` queue. This queue mostly behaves as Sidekiq Dead queue so it only stores a limited amount of jobs for a limited term. Same as for Dead queue, all the limits are configurable via `interrupted_max_jobs` (default: 10_000) and `interrupted_timeout_in_seconds` (default: 3 months) Sidekiq option keys.

You can also disable special handling of interrupted jobs by setting `max_retries_after_interruption` into `-1`.
In this case, interrupted jobs will be run without any limits from Reliable Fetcher and they won't be put into Interrupted queue.

You can define the `sidekiq_interruptions_exhausted` block to execute specific actions when a job is sent to the
`interrupted` queue after reaching the maximum allowed interruptions. For example, you might notify a user that the
job was interrupted multiple times and will no longer be retried.

The block receives a hash containing useful job details, including:

- `job['class']`: The worker class name.
- `job['args']`: Arguments passed to the job when it was enqueued.
- `job['jid']`: The unique job ID.
- `job['retry_count']`: The number of retry attempts made.
- `job['interrupted_count']`: The total number of times the job was interrupted.

#### Example Usage

```ruby
class MyWorker
  include Sidekiq::Worker
  include Sidekiq::InterruptionsExhausted

  sidekiq_interruptions_exhausted do |job|
    # Add your custom handling code here, for example:
    notify_user("Job #{job['class']} with ID #{job['jid']} was interrupted #{job['interrupted_count']} times and will no longer be retried.")
  end
end
```

## Installation

This gem is vendored in the GitLab Rails application and new versions are not published to RubyGems.

## Configuration

Enable reliable fetches by calling this gem from your Sidekiq configuration:

```ruby
Sidekiq.configure_server do |config|
  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)

  # …
end
```

There is an additional parameter `config[:semi_reliable_fetch]` you can use to switch between two strategies:

```ruby
Sidekiq.configure_server do |config|
  config[:semi_reliable_fetch] = true # Default value is false

  Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
end
```

## License

LGPL-3.0, see the LICENSE file.
