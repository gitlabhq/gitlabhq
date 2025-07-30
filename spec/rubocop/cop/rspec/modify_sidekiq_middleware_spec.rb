# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/modify_sidekiq_middleware'

RSpec.describe RuboCop::Cop::RSpec::ModifySidekiqMiddleware do
  it 'registers an offense and corrects', :aggregate_failures do
    expect_offense(<<~RUBY)
      Sidekiq::Testing.server_middleware do |chain|
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't modify global sidekiq middleware, [...]
        chain.add(MyCustomMiddleware)
      end
    RUBY

    expect_correction(<<~RUBY)
      with_sidekiq_server_middleware do |chain|
        chain.add(MyCustomMiddleware)
      end
    RUBY
  end
end
