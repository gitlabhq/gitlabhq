# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/sidekiq_load_balancing/worker_data_consistency'

RSpec.describe RuboCop::Cop::SidekiqLoadBalancing::WorkerDataConsistency, feature_category: :scalability do
  context 'when data_consistency is not set' do
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

  context 'when data_consistency set to :always' do
    it 'adds an offense when using `always` data_consistency' do
      expect_offense(<<~CODE)
        class SomeWorker
          include ApplicationWorker
          data_consistency :always
                           ^^^^^^^ Refrain from using `:always` if possible.[...]

          queue_namespace :pipeline_hooks
          feature_category :continuous_integration
          urgency :high
        end
      CODE
    end

    it 'adds no offense when using `sticky` data_consistency' do
      expect_no_offenses(<<~CODE)
        class SomeWorker
          include ApplicationWorker

          data_consistency :sticky
          queue_namespace :pipeline_hooks
          feature_category :continuous_integration
          urgency :high
        end
      CODE
    end

    it 'adds no offense when using `delayed` data_consistency' do
      expect_no_offenses(<<~CODE)
        class SomeWorker
          include ApplicationWorker

          data_consistency :delayed
          queue_namespace :pipeline_hooks
          feature_category :continuous_integration
          urgency :high
        end
      CODE
    end

    it 'adds no offense when worker is not an ApplicationWorker' do
      expect_no_offenses(<<~CODE)
        class SomeWorker
          data_consistency :always
          queue_namespace :pipeline_hooks
          feature_category :continuous_integration
          urgency :high
        end
      CODE
    end
  end
end
