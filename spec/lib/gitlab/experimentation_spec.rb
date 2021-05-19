# frozen_string_literal: true

require 'spec_helper'

# As each associated, backwards-compatible experiment gets cleaned up and removed from the EXPERIMENTS list, its key will also get removed from this list. Once the list here is empty, we can remove the backwards compatibility code altogether.
# Originally created as part of https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45733 for https://gitlab.com/gitlab-org/gitlab/-/issues/270858.
RSpec.describe Gitlab::Experimentation::EXPERIMENTS do
  it 'temporarily ensures we know what experiments exist for backwards compatibility' do
    expected_experiment_keys = [
      :invite_members_empty_group_version_a,
      :contact_sales_btn_in_app
    ]

    backwards_compatible_experiment_keys = described_class.filter { |_, v| v[:use_backwards_compatible_subject_index] }.keys

    expect(backwards_compatible_experiment_keys).not_to be_empty, "Oh, hey! Let's clean up that :use_backwards_compatible_subject_index stuff now :D"
    expect(backwards_compatible_experiment_keys).to match(expected_experiment_keys)
  end
end

RSpec.describe Gitlab::Experimentation do
  using RSpec::Parameterized::TableSyntax

  before do
    stub_const('Gitlab::Experimentation::EXPERIMENTS', {
      backwards_compatible_test_experiment: {
        tracking_category: 'Team',
        use_backwards_compatible_subject_index: true
      },
      test_experiment: {
        tracking_category: 'Team'
      },
      tabular_experiment: {
        tracking_category: 'Team',
        rollout_strategy: rollout_strategy
      }
    })

    skip_feature_flags_yaml_validation
    skip_default_enabled_yaml_check
    Feature.enable_percentage_of_time(:backwards_compatible_test_experiment_experiment_percentage, enabled_percentage)
    Feature.enable_percentage_of_time(:test_experiment_experiment_percentage, enabled_percentage)
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  let(:enabled_percentage) { 10 }
  let(:rollout_strategy) { nil }

  describe '.get_experiment' do
    subject { described_class.get_experiment(:test_experiment) }

    context 'returns experiment' do
      it { is_expected.to be_instance_of(Gitlab::Experimentation::Experiment) }
    end

    context 'experiment is not defined' do
      subject { described_class.get_experiment(:missing_experiment) }

      it { is_expected.to be_nil }
    end
  end

  describe '.active?' do
    subject { described_class.active?(:test_experiment) }

    context 'feature toggle is enabled' do
      it { is_expected.to eq(true) }
    end

    describe 'experiment is not defined' do
      it 'returns false' do
        expect(described_class.active?(:missing_experiment)).to eq(false)
      end
    end

    describe 'experiment is disabled' do
      let(:enabled_percentage) { 0 }

      it { is_expected.to eq(false) }
    end
  end

  describe '.in_experiment_group?' do
    context 'with new index calculation' do
      let(:enabled_percentage) { 50 }
      let(:experiment_subject) { 'z' } # Zlib.crc32('test_experimentz') % 100 = 33

      subject { described_class.in_experiment_group?(:test_experiment, subject: experiment_subject) }

      context 'when experiment is active' do
        context 'when subject is part of the experiment' do
          it { is_expected.to eq(true) }
        end

        context 'when subject is not part of the experiment' do
          let(:experiment_subject) { 'a' } # Zlib.crc32('test_experimenta') % 100 = 61

          it { is_expected.to eq(false) }
        end

        context 'when subject has a global_id' do
          let(:experiment_subject) { double(:subject, to_global_id: 'z') }

          it { is_expected.to eq(true) }
        end

        context 'when subject is nil' do
          let(:experiment_subject) { nil }

          it { is_expected.to eq(false) }
        end

        context 'when subject is an empty string' do
          let(:experiment_subject) { '' }

          it { is_expected.to eq(false) }
        end
      end

      context 'when experiment is not active' do
        before do
          allow(described_class).to receive(:active?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'with backwards compatible index calculation' do
      let(:experiment_subject) { 'abcd' } # Digest::SHA1.hexdigest('abcd').hex % 100 = 7

      subject { described_class.in_experiment_group?(:backwards_compatible_test_experiment, subject: experiment_subject) }

      context 'when experiment is active' do
        before do
          allow(described_class).to receive(:active?).and_return(true)
        end

        context 'when subject is part of the experiment' do
          it { is_expected.to eq(true) }
        end

        context 'when subject is not part of the experiment' do
          let(:experiment_subject) { 'abc' } # Digest::SHA1.hexdigest('abc').hex % 100 = 17

          it { is_expected.to eq(false) }
        end

        context 'when subject has a global_id' do
          let(:experiment_subject) { double(:subject, to_global_id: 'abcd') }

          it { is_expected.to eq(true) }
        end

        context 'when subject is nil' do
          let(:experiment_subject) { nil }

          it { is_expected.to eq(false) }
        end

        context 'when subject is an empty string' do
          let(:experiment_subject) { '' }

          it { is_expected.to eq(false) }
        end
      end

      context 'when experiment is not active' do
        before do
          allow(described_class).to receive(:active?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '.log_invalid_rollout' do
    subject { described_class.log_invalid_rollout(:test_experiment, 1) }

    before do
      allow(described_class).to receive(:valid_subject_for_rollout_strategy?).and_return(valid)
    end

    context 'subject is not valid for experiment' do
      let(:valid) { false }

      it 'logs a warning message' do
        expect_next_instance_of(Gitlab::ExperimentationLogger) do |logger|
          expect(logger)
            .to receive(:warn)
                  .with(
                    message: 'Subject must conform to the rollout strategy',
                    experiment_key: :test_experiment,
                    subject: 'Integer',
                    rollout_strategy: :cookie
                  )
        end

        subject
      end
    end

    context 'subject is valid for experiment' do
      let(:valid) { true }

      it 'does not log a warning message' do
        expect(Gitlab::ExperimentationLogger).not_to receive(:build)

        subject
      end
    end
  end

  describe '.valid_subject_for_rollout_strategy?' do
    subject { described_class.valid_subject_for_rollout_strategy?(:tabular_experiment, experiment_subject) }

    where(:rollout_strategy, :experiment_subject, :result) do
      :cookie | nil       | true
      nil     | nil       | true
      :cookie | 'string'  | true
      nil     | User.new  | false
      :user   | User.new  | true
      :group  | User.new  | false
      :group  | Group.new | true
    end

    with_them do
      it { is_expected.to be(result) }
    end
  end
end
