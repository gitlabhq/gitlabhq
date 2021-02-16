# frozen_string_literal: true

require 'spec_helper'
require_relative './simple_check_shared'

RSpec.describe Gitlab::HealthChecks::MasterCheck do
  before do
    stub_const('SUCCESS_CODE', 100)
    stub_const('FAILURE_CODE', 101)
  end

  context 'when Puma runs in Clustered mode' do
    before do
      allow(Gitlab::Runtime).to receive(:puma_in_clustered_mode?).and_return(true)

      described_class.register_master
    end

    after do
      described_class.finish_master
    end

    describe '.available?' do
      specify { expect(described_class.available?).to be true }
    end

    describe '.readiness' do
      context 'when master is running' do
        it 'worker does return success' do
          _, child_status = run_worker

          expect(child_status.exitstatus).to eq(SUCCESS_CODE)
        end
      end

      context 'when master finishes early' do
        before do
          described_class.send(:close_write)
        end

        it 'worker does return failure' do
          _, child_status = run_worker

          expect(child_status.exitstatus).to eq(FAILURE_CODE)
        end
      end

      def run_worker
        pid = fork do
          described_class.register_worker

          exit(described_class.readiness.success ? SUCCESS_CODE : FAILURE_CODE)
        end

        Process.wait2(pid)
      end
    end
  end

  # '.readiness' check is not invoked if '.available?' returns false
  context 'when Puma runs in Single mode' do
    before do
      allow(Gitlab::Runtime).to receive(:puma_in_clustered_mode?).and_return(false)
    end

    describe '.available?' do
      specify { expect(described_class.available?).to be false }
    end
  end
end
