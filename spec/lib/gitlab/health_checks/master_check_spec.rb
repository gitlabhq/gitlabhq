# frozen_string_literal: true

require 'spec_helper'
require_relative './simple_check_shared'

RSpec.describe Gitlab::HealthChecks::MasterCheck do
  let(:result_class) { Gitlab::HealthChecks::Result }

  before do
    stub_const('SUCCESS_CODE', 100)
    stub_const('FAILURE_CODE', 101)
    described_class.register_master
  end

  after do
    described_class.finish_master
  end

  describe '#readiness' do
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
