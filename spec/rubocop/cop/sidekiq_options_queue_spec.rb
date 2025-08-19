# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/sidekiq_options_queue'

RSpec.describe RuboCop::Cop::SidekiqOptionsQueue do
  it 'registers an offense when `sidekiq_options` is used with the `queue` option' do
    expect_offense(<<~RUBY)
      sidekiq_options queue: "some_queue"
                      ^^^^^^^^^^^^^^^^^^^ Do not manually set a queue; `ApplicationWorker` sets one automatically.
    RUBY
  end

  it 'does not register an offense when `sidekiq_options` is used with another option' do
    expect_no_offenses('sidekiq_options retry: false')
  end
end
