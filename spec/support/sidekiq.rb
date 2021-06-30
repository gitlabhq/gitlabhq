# frozen_string_literal: true

RSpec.configure do |config|
  def gitlab_sidekiq_inline(&block)
    # We need to cleanup the queues before running jobs in specs because the
    # middleware might have written to redis
    redis_queues_cleanup!
    Sidekiq::Testing.inline!(&block)
  ensure
    redis_queues_cleanup!
  end

  # As we'll review the examples with this tag, we should either:
  # - fix the example to not require Sidekiq inline mode (and remove this tag)
  # - explicitly keep the inline mode and change the tag for `:sidekiq_inline` instead
  config.around(:example, :sidekiq_might_not_need_inline) do |example|
    gitlab_sidekiq_inline { example.run }
  end

  config.around(:example, :sidekiq_inline) do |example|
    gitlab_sidekiq_inline { example.run }
  end

  # Some specs need to run mailers through Sidekiq explicitly, rather
  # than the ActiveJob test adapter. There is a Rails bug that means we
  # have to do some extra steps to make this happen:
  # https://github.com/rails/rails/issues/37270
  #
  # In particular, we can't use an `around` hook because then the 'before' part
  # of that will run before the `before_setup` hook in ActiveJob::TestHelper,
  # which doesn't do what we want.
  #
  config.before(:example, :sidekiq_mailers) do
    queue_adapter_changed_jobs.each { |k| k.queue_adapter = :sidekiq }
    queue_adapter_changed_jobs.each(&:disable_test_adapter)
  end

  config.after(:example, :sidekiq_mailers) do
    queue_adapter_changed_jobs.each do |klass|
      klass.queue_adapter = :test
      klass.enable_test_adapter(ActiveJob::QueueAdapters::TestAdapter.new)
    end
  end
end
