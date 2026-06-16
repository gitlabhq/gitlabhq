# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe SystemCheck::GitalyCheck, :silence_stdout, feature_category: :gitaly do
  subject(:checker) { described_class.new }

  describe '#multi_check' do
    context 'when shard check succeeds' do
      let(:result) { instance_double(Gitlab::HealthChecks::Result, success: true, labels: { shard: 'default' }) }

      before do
        allow(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness).and_return([result])
      end

      it 'prints OK' do
        expect($stdout).to receive(:puts).with(Rainbow('OK').green)

        checker.multi_check
      end
    end

    context 'when shard check fails' do
      let(:result) do
        instance_double(Gitlab::HealthChecks::Result, success: false, message: 'timeout', labels: { shard: 'default' })
      end

      before do
        allow(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness).and_return([result])
      end

      it 'prints FAIL with error message' do
        expect($stdout).to receive(:puts).with(Rainbow('FAIL: timeout').red)

        checker.multi_check
      end
    end
  end
end
