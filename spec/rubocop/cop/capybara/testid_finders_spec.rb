# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/capybara/testid_finders'

RSpec.describe RuboCop::Cop::Capybara::TestidFinders, feature_category: :shared do
  let(:source_file) { 'spec/features/foo_spec.rb' }

  describe 'good examples' do
    where(:code) do
      [
        "find_by_testid('some-testid')",
        "find_by_testid('\#{testid}')",
        "find('[data-testid=\"some-testid\"] > input')",
        "find('[data-tracking=\"render\"]')",
        "within_testid('some-testid')",
        "within_testid('\#{testid}')",
        "within('[data-testid=\"some-testid\"] > input')",
        "within('[data-tracking=\"render\"]')"
      ]
    end

    with_them do
      it 'does not register an offense' do
        expect_no_offenses(code)
      end
    end
  end

  describe 'bad examples' do
    where(:code) do
      [
        "find('[data-testid=\"some-testid\"]')",
        "find(\"[data-testid='some-testid']\")",
        "within('[data-testid=\"some-testid\"]')",
        "within(\"[data-testid='some-testid']\")"
      ]
    end

    with_them do
      it 'does not register an offense' do
        expect_offense(<<~CODE, node: code)
          %{node}
          ^{node} Prefer to use custom helper method[...]
        CODE
      end
    end
  end
end
