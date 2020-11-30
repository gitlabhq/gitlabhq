# frozen_string_literal: true

require 'spec_helper'

# As each associated, backwards-compatible experiment gets cleaned up and removed from the EXPERIMENTS list, its key will also get removed from this list. Once the list here is empty, we can remove the backwards compatibility code altogether.
# Originally created as part of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45733 for https://gitlab.com/gitlab-org/gitlab/-/issues/270858.
RSpec.describe Gitlab::Experimentation::EXPERIMENTS do
  it 'temporarily ensures we know what experiments exist for backwards compatibility' do
    expected_experiment_keys = [
      :onboarding_issues,
      :ci_notification_dot,
      :upgrade_link_in_user_menu_a,
      :invite_members_version_a,
      :invite_members_version_b,
      :invite_members_empty_group_version_a,
      :contact_sales_btn_in_app,
      :customize_homepage,
      :invite_email,
      :invitation_reminders,
      :group_only_trials,
      :default_to_issues_board
    ]

    backwards_compatible_experiment_keys = described_class.filter { |_, v| v[:use_backwards_compatible_subject_index] }.keys

    expect(backwards_compatible_experiment_keys).not_to be_empty, "Oh, hey! Let's clean up that :use_backwards_compatible_subject_index stuff now :D"
    expect(backwards_compatible_experiment_keys).to match(expected_experiment_keys)
  end
end

RSpec.describe Gitlab::Experimentation, :snowplow do
  before do
    stub_const('Gitlab::Experimentation::EXPERIMENTS', {
      backwards_compatible_test_experiment: {
        tracking_category: 'Team',
        use_backwards_compatible_subject_index: true
      },
      test_experiment: {
        tracking_category: 'Team'
      }
    })

    Feature.enable_percentage_of_time(:backwards_compatible_test_experiment_experiment_percentage, enabled_percentage)
    Feature.enable_percentage_of_time(:test_experiment_experiment_percentage, enabled_percentage)
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  let(:enabled_percentage) { 10 }

  describe '.enabled?' do
    subject { described_class.enabled?(:test_experiment) }

    context 'feature toggle is enabled and we are selected' do
      it { is_expected.to be_truthy }
    end

    describe 'experiment is not defined' do
      it 'returns false' do
        expect(described_class.enabled?(:missing_experiment)).to be_falsey
      end
    end

    describe 'experiment is disabled' do
      let(:enabled_percentage) { 0 }

      it { is_expected.to be_falsey }
    end
  end

  describe '.enabled_for_value?' do
    subject { described_class.enabled_for_value?(:test_experiment, experimentation_subject_index) }

    let(:experimentation_subject_index) { 9 }

    context 'experiment is disabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'experiment is enabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(true)
      end

      it { is_expected.to be_truthy }

      describe 'experimentation_subject_index' do
        context 'experimentation_subject_index is not set' do
          let(:experimentation_subject_index) { nil }

          it { is_expected.to be_falsey }
        end

        context 'experimentation_subject_index is an empty string' do
          let(:experimentation_subject_index) { '' }

          it { is_expected.to be_falsey }
        end

        context 'experimentation_subject_index outside enabled ratio' do
          let(:experimentation_subject_index) { 11 }

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '.enabled_for_attribute?' do
    subject { described_class.enabled_for_attribute?(:test_experiment, attribute) }

    let(:attribute) { 'abcd' } # Digest::SHA1.hexdigest('abcd').hex % 100 = 7

    context 'experiment is disabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(false)
      end

      it { is_expected.to be false }
    end

    context 'experiment is enabled' do
      before do
        allow(described_class).to receive(:enabled?).and_return(true)
      end

      it { is_expected.to be true }

      context 'outside enabled ratio' do
        let(:attribute) { 'abc' } # Digest::SHA1.hexdigest('abc').hex % 100 = 17

        it { is_expected.to be false }
      end
    end
  end
end
