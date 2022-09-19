# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/modify_sidekiq_middleware'

RSpec.describe RuboCop::Cop::RSpec::ModifySidekiqMiddleware do
  it 'registers an offense and corrects', :aggregate_failures do
    expect_offense(<<~CODE)
      Sidekiq::Testing.server_middleware do |chain|
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't modify global sidekiq middleware, [...]
        chain.add(MyCustomMiddleware)
      end
    CODE

    expect_correction(<<~CODE)
      with_sidekiq_server_middleware do |chain|
        chain.add(MyCustomMiddleware)
      end
    CODE
  end
end
