# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :sidekiq) do |example|
    Sidekiq::Worker.clear_all
    example.run
    Sidekiq::Worker.clear_all
  end

  config.after(:each, :sidekiq, :redis) do
    Sidekiq.redis do |connection|
      connection.redis.flushdb
    end
  end

  # As we'll review the examples with this tag, we should either:
  # - fix the example to not require Sidekiq inline mode (and remove this tag)
  # - explicitly keep the inline mode and change the tag for `:sidekiq_inline` instead
  config.around(:example, :sidekiq_might_not_need_inline) do |example|
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.inline! { example.run }
    Sidekiq::Worker.clear_all
  end

  config.around(:example, :sidekiq_inline) do |example|
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.inline! { example.run }
    Sidekiq::Worker.clear_all
  end
end
