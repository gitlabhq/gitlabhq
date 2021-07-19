# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/worker_data_consistency'

RSpec.describe RuboCop::Cop::WorkerDataConsistency do
  subject(:cop) { described_class.new }

  before do
    allow(cop)
      .to receive(:in_worker?)
      .and_return(true)
  end

  it 'adds an offense when not defining data_consistency' do
    expect_offense(<<~CODE)
      class SomeWorker
      ^^^^^^^^^^^^^^^^ Should define data_consistency expectation.[...]
        include ApplicationWorker

        queue_namespace :pipeline_hooks
        feature_category :continuous_integration
        urgency :high
      end
    CODE
  end

  it 'adds no offense when defining data_consistency' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        include ApplicationWorker

        queue_namespace :pipeline_hooks
        feature_category :continuous_integration
        data_consistency :delayed
        urgency :high
      end
    CODE
  end

  it 'adds no offense when worker is not an ApplicationWorker' do
    expect_no_offenses(<<~CODE)
      class SomeWorker
        queue_namespace :pipeline_hooks
        feature_category :continuous_integration
        urgency :high
      end
    CODE
  end
end
