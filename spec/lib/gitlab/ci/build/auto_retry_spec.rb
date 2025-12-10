# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::AutoRetry, feature_category: :pipeline_composition do
  let(:auto_retry) { described_class.new(build) }

  describe '#allowed?' do
    using RSpec::Parameterized::TableSyntax

    let(:build) { build_stubbed(:ci_build) }

    subject { auto_retry.allowed? }

    where(:description, :retry_count, :options, :failure_reason, :exit_code, :result) do
      # retry:max
      "retries are disabled" | 0 | { max: 0 } | nil | nil | false
      "max equals count" | 2 | { max: 2 } | nil | nil | false
      "max is higher than count" | 1 | { max: 2 } | nil | nil | true
      "max is a string" | 1 | { max: '2' } | nil | nil | true
      # retry:when
      "matching failure reason" | 0 | { when: %w[api_failure], max: 2 } | :api_failure | nil | true
      "not matching with always" | 0 | { when: %w[always], max: 2 } | :api_failure | nil | true
      "not matching reason" | 0 | { when: %w[script_error], max: 2 } | :api_failure | nil | false
      "scheduler failure override" | 1 | { when: %w[scheduler_failure], max: 1 } | :scheduler_failure | nil | false
      # retry:exit_codes
      "matching exit code" | 0 | { exit_codes: [255, 137], max: 2 } | nil | 137 | true
      "matching exit code simple" | 0 | { exit_codes: [255], max: 2 } | nil | 255 | true
      "not matching exit code" | 0 | { exit_codes: [255], max: 2 } | nil | 1 | false
      "exit_code is not an integer" | 0 | { exit_codes: ["137"], max: 2 } | nil | 137 | false
      # retry:when && retry:exit_codes
      # EC: exit_codes
      # FR: failure_reason
      "matching EC & FR" | 0 | { exit_codes: [3], when: %w[script_failure], max: 2 } | :script_failure | 3 | true
      "matching EC only" | 0 | { exit_codes: [3], when: %w[script_failure], max: 2 } | :api_failure | 3 | true
      "matching FR only" | 0 | { exit_codes: [1], when: %w[script_failure], max: 2 } | :script_failure | 137 | true
      "not matching EC & FR" | 0 | { exit_codes: [1], when: %w[script_failure], max: 2 } | :api_failure | 137 | false
      # other
      "default for scheduler failure" | 1 | {} | :scheduler_failure | nil | true
      "quota is exceeded" | 0 | { max: 2 } | :ci_quota_exceeded | nil | false
      "no matching runner" | 0 | { max: 2 } | :no_matching_runner | nil | false
      "missing dependencies" | 0 | { max: 2 } | :missing_dependency_failure | nil | false
      "forward deployment failure" | 0 | { max: 2 } | :forward_deployment_failure | nil | false
      "environment creation failure" | 0 | { max: 2 } | :environment_creation_failure | nil | false
    end

    with_them do
      before do
        allow(build).to receive(:retries_count) { retry_count }

        build.options[:retry] = options
        build.failure_reason = failure_reason
        build.exit_code = exit_code
        allow(build).to receive(:retryable?).and_return(true)
      end

      it { is_expected.to eq(result) }
    end

    context 'when build is not retryable' do
      before do
        allow(build).to receive(:retryable?).and_return(false)
      end

      specify { expect(subject).to eq(false) }
    end
  end

  describe '#options_retry_max' do
    subject(:result) { auto_retry.send(:options_retry_max) }

    context 'with retries max config option' do
      let(:build) { create(:ci_build, options: { retry: { max: 1 } }) }

      it 'returns the number of configured max retries' do
        expect(result).to eq 1
      end
    end

    context 'without retries max config option' do
      let(:build) { create(:ci_build) }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when build is degenerated' do
      let(:build) { create(:ci_build, :degenerated) }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'with integer only config option' do
      let(:build) { create(:ci_build, options: { retry: 1 }) }

      it 'returns the number of configured max retries' do
        expect(result).to eq 1
      end
    end
  end

  describe '#options_retry_when' do
    subject(:result) { auto_retry.send(:options_retry_when) }

    context 'with retries when config option' do
      let(:build) { create(:ci_build, options: { retry: { when: ['some_reason'] } }) }

      it 'returns the configured when' do
        expect(result).to eq ['some_reason']
      end
    end

    context 'without retries when config option' do
      let(:build) { create(:ci_build) }

      it 'returns always array' do
        expect(result).to eq ['always']
      end
    end

    context 'with integer only config option' do
      let(:build) { create(:ci_build, options: { retry: 1 }) }

      it 'returns always array' do
        expect(result).to eq ['always']
      end
    end

    context 'with retry[:when] set to nil' do
      let(:build) { create(:ci_build, options: { retry: { when: nil } }) }

      it 'returns always array' do
        expect(result).to eq ['always']
      end
    end
  end
end
