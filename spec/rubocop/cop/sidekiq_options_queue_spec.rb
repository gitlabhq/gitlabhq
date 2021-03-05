# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../rubocop/cop/sidekiq_options_queue'

RSpec.describe RuboCop::Cop::SidekiqOptionsQueue do
  subject(:cop) { described_class.new }

  it 'registers an offense when `sidekiq_options` is used with the `queue` option' do
    expect_offense(<<~CODE)
      sidekiq_options queue: "some_queue"
                      ^^^^^^^^^^^^^^^^^^^ Do not manually set a queue; `ApplicationWorker` sets one automatically.
    CODE
  end

  it 'does not register an offense when `sidekiq_options` is used with another option' do
    expect_no_offenses('sidekiq_options retry: false')
  end
end
