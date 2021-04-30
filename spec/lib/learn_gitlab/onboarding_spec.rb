# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearnGitlab::Onboarding do
  describe '#completed_percentage' do
    let(:completed_actions) { {} }
    let(:onboarding_progress) { build(:onboarding_progress, namespace: namespace, **completed_actions) }
    let(:namespace) { build(:namespace) }

    let_it_be(:tracked_action_columns) do
      tracked_actions = described_class::ACTION_ISSUE_IDS.keys + described_class::ACTION_DOC_URLS.keys
      tracked_actions.map { |key| OnboardingProgress.column_name(key) }
    end

    before do
      expect(OnboardingProgress).to receive(:find_by).with(namespace: namespace).and_return(onboarding_progress)
    end

    subject { described_class.new(namespace).completed_percentage }

    context 'when no onboarding_progress exists' do
      let(:onboarding_progress) { nil }

      it { is_expected.to eq(0) }
    end

    context 'when no action has been completed' do
      it { is_expected.to eq(0) }
    end

    context 'when one action has been completed' do
      let(:completed_actions) { Hash[tracked_action_columns.first, Time.current] }

      it { is_expected.to eq(11) }
    end

    context 'when all tracked actions have been completed' do
      let(:completed_actions) do
        tracked_action_columns.to_h { |action| [action, Time.current] }
      end

      it { is_expected.to eq(100) }
    end
  end
end
