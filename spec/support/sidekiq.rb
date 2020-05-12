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
end
