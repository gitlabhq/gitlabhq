# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Queue::Metrics, feature_category: :continuous_integration do
  let(:metrics) { described_class.new(build(:ci_runner)) }

  describe '#observe_queue_depth' do
    subject { metrics.observe_queue_depth(:found, 1) }

    it { is_expected.not_to be_nil }

    context 'with feature flag gitlab_ci_builds_queueing_metrics disabled' do
      before do
        stub_feature_flags(gitlab_ci_builds_queuing_metrics: false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#observe_queue_size' do
    subject { metrics.observe_queue_size(-> { 0 }, :some_runner_type) }

    it { is_expected.not_to be_nil }

    context 'with feature flag gitlab_ci_builds_queueing_metrics disabled' do
      before do
        stub_feature_flags(gitlab_ci_builds_queuing_metrics: false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#observe_queue_time' do
    subject { metrics.observe_queue_time(:process, :some_runner_type) { 1 } }

    specify do
      expect(described_class).to receive(:queue_iteration_duration_seconds).and_call_original

      subject
    end

    context 'with feature flag gitlab_ci_builds_queueing_metrics disabled' do
      before do
        stub_feature_flags(gitlab_ci_builds_queuing_metrics: false)
      end

      specify do
        expect(described_class).not_to receive(:queue_iteration_duration_seconds)

        subject
      end
    end

    describe '.observe_active_runners' do
      subject { described_class.observe_active_runners(-> { 0 }) }

      it { is_expected.not_to be_nil }

      context 'with feature flag gitlab_ci_builds_queueing_metrics disabled' do
        before do
          stub_feature_flags(gitlab_ci_builds_queuing_metrics: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end
end
