# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/avoid_wait_for_requests'

RSpec.describe RuboCop::Cop::RSpec::AvoidWaitForRequests, feature_category: :tooling do
  context 'when using wait_for_requests' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        wait_for_requests
        ^^^^^^^^^^^^^^^^^ Avoid `wait_for_requests` in feature specs. Instead, assert on a UI change to ensure the request has completed. See https://docs.gitlab.com/development/testing_guide/frontend_testing/#assertions.
      RUBY
    end
  end

  context 'when using wait_for_all_requests' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        wait_for_all_requests
        ^^^^^^^^^^^^^^^^^^^^^ Avoid `wait_for_all_requests` in feature specs. Instead, assert on a UI change to ensure the request has completed. See https://docs.gitlab.com/development/testing_guide/frontend_testing/#assertions.
      RUBY
    end
  end

  context 'when using other methods' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        wait_for_something_else
      RUBY
    end
  end
end
