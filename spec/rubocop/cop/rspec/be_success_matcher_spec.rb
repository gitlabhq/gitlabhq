# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/be_success_matcher'

RSpec.describe RuboCop::Cop::RSpec::BeSuccessMatcher, feature_category: :shared do
  let(:source_file) { 'spec/foo_spec.rb' }

  shared_examples 'cop' do |good:, bad:|
    context "using #{bad} call" do
      it 'registers an offense and corrects', :aggregate_failures do
        expect_offense(<<~RUBY, node: bad)
          %{node}
          ^{node} Do not use `be_success` (wraps deprecated `success?`); use `be_successful` instead.
        RUBY

        expect_correction(<<~RUBY)
          #{good}
        RUBY
      end
    end

    context "using #{good} call" do
      it 'does not register an offense' do
        expect_no_offenses(good)
      end
    end
  end

  include_examples 'cop',
    bad: 'expect(response).to be_success',
    good: 'expect(response).to be_successful'

  include_examples 'cop',
    bad: 'expect(response).to_not be_success',
    good: 'expect(response).to_not be_successful'

  include_examples 'cop',
    bad: 'expect(response).not_to be_success',
    good: 'expect(response).not_to be_successful'

  include_examples 'cop',
    bad: 'is_expected.to be_success',
    good: 'is_expected.to be_successful'

  include_examples 'cop',
    bad: 'is_expected.to_not be_success',
    good: 'is_expected.to_not be_successful'

  include_examples 'cop',
    bad: 'is_expected.not_to be_success',
    good: 'is_expected.not_to be_successful'
end
