# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rails/avoid_time_comparison'

RSpec.describe RuboCop::Cop::Rails::AvoidTimeComparison, feature_category: :shared do
  shared_examples 'using time comparison' do
    let(:violation_string_length) { "datetime > #{time}".length }

    it 'flags violation' do
      expect_offense(<<~RUBY)
        datetime > #{time}
        #{'^' * violation_string_length} Avoid time comparison, use `.past?` or `.future?` instead.
      RUBY

      expect_offense(<<~RUBY)
        datetime < #{time}
        #{'^' * violation_string_length} Avoid time comparison, use `.past?` or `.future?` instead.
      RUBY

      expect_offense(<<~RUBY)
        #{time} < datetime
        #{'^' * violation_string_length} Avoid time comparison, use `.past?` or `.future?` instead.
      RUBY
    end
  end

  context 'when comparing with Time.now', :aggregate_failures do
    let(:time) { 'Time.now' }

    it_behaves_like 'using time comparison'
  end

  context 'when comparing with ::Time.now', :aggregate_failures do
    let(:time) { '::Time.now' }

    it_behaves_like 'using time comparison'
  end

  context 'when comparing with Time.zone.now', :aggregate_failures do
    let(:time) { 'Time.zone.now' }

    it_behaves_like 'using time comparison'
  end

  context 'when comparing with Time.current', :aggregate_failures do
    let(:time) { 'Time.current' }

    it_behaves_like 'using time comparison'
  end

  it 'does not flag assigning time methods to variables' do
    expect_no_offenses(<<~RUBY)
      datetime = Time.now
    RUBY
  end
end
