# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Status::Reason do
  let(:build) { double('build') }

  describe '.fabricate' do
    context 'when failure symbol reason is being passed' do
      it 'correctly fabricates a status reason object' do
        reason = described_class.fabricate(build, :script_failure)

        expect(reason.failure_reason_enum).to eq 1
      end
    end

    context 'when another status reason object is being passed' do
      it 'correctly fabricates a status reason object' do
        reason = described_class.fabricate(build, :script_failure)

        new_reason = described_class.fabricate(build, reason)

        expect(new_reason.failure_reason_enum).to eq 1
      end
    end
  end

  describe '#failure_reason_enum' do
    it 'exposes a failure reason enum' do
      reason = described_class.fabricate(build, :script_failure)

      enum = ::CommitStatus.failure_reasons[:script_failure]

      expect(reason.failure_reason_enum).to eq enum
    end
  end

  describe '#force_allow_failure?' do
    context 'when build is not allowed to fail' do
      context 'when build is allowed to fail with a given exit code' do
        it 'returns true' do
          reason = described_class.new(build, :script_failure, 11)

          allow(build).to receive(:allow_failure?).and_return(false)
          allow(build).to receive(:allowed_to_fail_with_code?)
            .with(11)
            .and_return(true)

          expect(reason.force_allow_failure?).to be true
        end
      end

      context 'when build is not allowed to fail regardless of an exit code' do
        it 'returns false' do
          reason = described_class.new(build, :script_failure, 11)

          allow(build).to receive(:allow_failure?).and_return(false)
          allow(build).to receive(:allowed_to_fail_with_code?)
            .with(11)
            .and_return(false)

          expect(reason.force_allow_failure?).to be false
        end
      end

      context 'when an exit code is not specified' do
        it 'returns false' do
          reason = described_class.new(build, :script_failure)

          expect(reason.force_allow_failure?).to be false
        end
      end
    end
  end
end
