# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Matching::EnvironmentKey, feature_category: :runner_core do
  describe '#runner_id' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(environment_key).runner_id }

    where(:case_name, :environment_key, :expected) do
      # @formatter:off - RubyMine does not format table well
      'valid positional key'    | '22/s_abc/executor-specific-data'     | 22
      'zero runner id'          | '0/s_abc/executor-specific-data'      | nil
      'non-integer runner id'   | 'abc/s_abc/executor-specific-data'    | nil
      'only two segments'       | '22/executor-specific-data'           | nil
      'no slashes'              | 'no-slash-here'                       | nil
      'empty string'            | ''                                    | nil
      'nil'                     | nil                                   | nil
      # @formatter:on
    end

    with_them do
      it { is_expected.to eq(expected) }
    end

    context 'when environment_key exceeds MAX_ENVIRONMENT_KEY_LENGTH' do
      let(:environment_key) { "22/s_abc/#{'a' * described_class::MAX_ENVIRONMENT_KEY_LENGTH}" }

      it { is_expected.to be_nil }
    end
  end

  describe '#system_id' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.new(environment_key).system_id }

    where(:case_name, :environment_key, :expected) do
      # @formatter:off - RubyMine does not format table well
      'valid positional key'                    | '22/s_abc123/executor-specific-data'    | 's_abc123'
      'percent-encoded slash in system_id'      | '22/s%2Fabc/executor-specific-data'     | 's/abc'
      'percent-encoded space in system_id'      | '22/s%20abc/executor-specific-data'     | 's abc'
      'percent-encoded plus in system_id'       | '22/s%2Babc/executor-specific-data'     | 's+abc'
      'unencoded ASCII system_id passthrough'   | '22/s_plain123/executor-specific-data'  | 's_plain123'
      'malformed percent sequence'              | '22/s%2xyz/executor-specific-data'      | 's%2xyz'
      'only two segments'                       | '22/executor-specific-data'             | nil
      'empty second segment'                    | '22//executor-specific-data'            | nil
      'nil'                                     | nil                                     | nil
      # @formatter:on
    end

    with_them do
      it { is_expected.to eq(expected) }
    end

    context 'when environment_key exceeds MAX_ENVIRONMENT_KEY_LENGTH' do
      let(:environment_key) { "22/s_abc/#{'a' * described_class::MAX_ENVIRONMENT_KEY_LENGTH}" }

      it { is_expected.to be_nil }
    end
  end

  describe '#matches_runner?' do
    let(:runner) do
      instance_double(
        "Ci::Runner", # rubocop:disable RSpec/VerifiedDoubleReference -- quoted to allow fast_spec_helper
        id: 22
      )
    end

    let(:runner_manager) do
      instance_double(
        "Ci::RunnerManager", # rubocop:disable RSpec/VerifiedDoubleReference -- quoted to allow fast_spec_helper
        system_xid: "s_abc123xyz"
      )
    end

    subject do
      described_class.new(environment_key).matches_runner?(runner, runner_manager: runner_manager)
    end

    context 'when runner_id and system_id both match' do
      let(:environment_key) { '22/s_abc123xyz/executor-specific-data' }

      it { is_expected.to be(true) }
    end

    context 'when runner_id matches but system_id does not' do
      let(:environment_key) { '22/s_other/executor-specific-data' }

      it { is_expected.to be(false) }
    end

    context 'when runner_id does not match' do
      let(:environment_key) { '99/s_abc123xyz/executor-specific-data' }

      it { is_expected.to be(false) }
    end

    context 'when key has only two segments (no system_id)' do
      let(:environment_key) { '22/executor-specific-data' }

      it { is_expected.to be(false) }
    end

    context 'when runner_manager is nil' do
      let(:environment_key) { '22/s_abc123xyz/executor-specific-data' }
      let(:runner_manager) { nil }

      it { is_expected.to be(false) }
    end

    context 'when environment_key is nil' do
      let(:environment_key) { nil }

      it { is_expected.to be(false) }
    end

    context 'when system_id is percent-encoded and matches decoded runner_manager system_xid' do
      let(:runner_manager) do
        instance_double(
          "Ci::RunnerManager", # rubocop:disable RSpec/VerifiedDoubleReference -- quoted to allow fast_spec_helper
          system_xid: "s/abc"
        )
      end

      let(:environment_key) { '22/s%2Fabc/executor-specific-data' }

      it { is_expected.to be(true) }
    end
  end
end
