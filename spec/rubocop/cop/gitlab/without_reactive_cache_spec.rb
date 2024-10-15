# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/without_reactive_cache'

RSpec.describe RuboCop::Cop::Gitlab::WithoutReactiveCache, feature_category: :shared do
  it 'registers an offense when without_reactive_cache is used' do
    expect_offense(<<~RUBY)
      without_reactive_cache do; end
      ^^^^^^^^^^^^^^^^^^^^^^ without_reactive_cache is for debugging purposes only. Please use with_reactive_cache.
    RUBY
  end

  it 'does not flag unsupported methods' do
    expect_no_offenses(<<~RUBY)
      something_else do; end
    RUBY
  end
end
