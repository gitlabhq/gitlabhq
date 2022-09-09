# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::Completion do
  describe '#percentage' do
    let(:completed_actions) { {} }
    let!(:onboarding_progress) { create(:onboarding_progress, namespace: namespace, **completed_actions) }
    let(:tracked_action_columns) do
      [
        *described_class::ACTION_ISSUE_IDS.keys,
        *described_class::ACTION_PATHS,
        :security_scan_enabled
      ].map { |key| ::Onboarding::Progress.column_name(key) }
    end

    let_it_be(:namespace) { create(:namespace) }

    subject { described_class.new(namespace).percentage }

    context 'when no onboarding_progress exists' do
      subject { described_class.new(build(:namespace)).percentage }

      it { is_expected.to eq(0) }
    end

    context 'when no action has been completed' do
      it { is_expected.to eq(0) }
    end

    context 'when all tracked actions have been completed' do
      let(:completed_actions) do
        tracked_action_columns.index_with { Time.current }
      end

      it { is_expected.to eq(100) }
    end

    context 'with security_actions_continuous_onboarding experiment' do
      let(:completed_actions) { Hash[tracked_action_columns.first, Time.current] }

      context 'when control' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :control)
        end

        it { is_expected.to eq(11) }
      end

      context 'when candidate' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :candidate)
        end

        it { is_expected.to eq(9) }
      end
    end
  end
end
