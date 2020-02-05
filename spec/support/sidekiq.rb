# frozen_string_literal: true

RSpec.configure do |config|
  # As we'll review the examples with this tag, we should either:
  # - fix the example to not require Sidekiq inline mode (and remove this tag)
  # - explicitly keep the inline mode and change the tag for `:sidekiq_inline` instead
  config.around(:example, :sidekiq_might_not_need_inline) do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  config.around(:example, :sidekiq_inline) do |example|
    Sidekiq::Testing.inline! { example.run }
  end
end
