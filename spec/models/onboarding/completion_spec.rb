# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::Completion, feature_category: :onboarding do
  let(:completed_actions) { {} }
  let(:project) { build(:project, namespace: namespace) }
  let!(:onboarding_progress) { create(:onboarding_progress, namespace: namespace, **completed_actions) }

  let_it_be(:namespace) { create(:namespace) }

  describe '#percentage' do
    let(:tracked_action_columns) do
      [*described_class::ACTION_PATHS, :security_scan_enabled].map do |key|
        ::Onboarding::Progress.column_name(key)
      end
    end

    subject(:percentage) { described_class.new(project).percentage }

    context 'when no onboarding_progress exists' do
      subject(:percentage) { described_class.new(build(:project)).percentage }

      it { is_expected.to eq(0) }
    end

    context 'when no action has been completed' do
      it { is_expected.to eq(0) }
    end

    context 'when all tracked actions have been completed' do
      let(:project) { build(:project, :stubbed_commit_count, namespace: namespace) }

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

        it { is_expected.to eq(10) }
      end

      context 'when candidate' do
        before do
          stub_experiments(security_actions_continuous_onboarding: :candidate)
        end

        it { is_expected.to eq(8) }
      end
    end
  end

  describe '#completed?' do
    subject(:completed?) { described_class.new(project).completed?(column) }

    context 'when code_added' do
      let(:column) { :code_added }

      context 'when commit_count > 1' do
        let(:project) { build(:project, :stubbed_commit_count, namespace: namespace) }

        it { is_expected.to eq(true) }
      end

      context 'when branch_count > 1' do
        let(:project) { build(:project, :stubbed_branch_count, namespace: namespace) }

        it { is_expected.to eq(true) }
      end

      context 'when empty repository' do
        let(:project) { build(:project, namespace: namespace) }

        it { is_expected.to eq(false) }
      end
    end

    context 'when security_scan_enabled' do
      let(:column) { :security_scan_enabled_at }
      let(:completed_actions) { { security_scan_enabled_at: security_scan_enabled_at } }

      context 'when is completed' do
        let(:security_scan_enabled_at) { Time.current }

        it { is_expected.to eq(true) }
      end

      context 'when is not completed' do
        let(:security_scan_enabled_at) { nil }

        it { is_expected.to eq(false) }
      end
    end
  end
end
