# frozen_string_literal: true

require 'fast_spec_helper'
require 'open3'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/resolve_repo_root'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::ResolveRepoRoot, feature_category: :tooling do
  describe '.resolve' do
    let(:context) { { argv: [], results: [] } }
    let(:success_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }
    let(:failure_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

    it 'adds repo_root to context' do
      allow(Open3).to receive(:capture3).with('git', 'rev-parse', '--show-toplevel').and_return(
        ["/some/repo\n", '', success_status]
      )

      result = described_class.resolve(context)

      expect(result[:repo_root]).to eq('/some/repo')
    end

    it 'returns the context hash' do
      allow(Open3).to receive(:capture3).with('git', 'rev-parse', '--show-toplevel').and_return(
        ["/some/repo\n", '', success_status]
      )

      result = described_class.resolve(context)

      expect(result).to be(context)
    end

    it 'raises when git rev-parse returns an empty string' do
      allow(Open3).to receive(:capture3).with('git', 'rev-parse', '--show-toplevel').and_return(
        ["\n", '', success_status]
      )

      expect { described_class.resolve(context) }.to raise_error(RuntimeError, /Failed to determine git repo root/)
    end

    it 'raises when git rev-parse exits with non-zero status' do
      allow(Open3).to receive(:capture3).with('git', 'rev-parse', '--show-toplevel').and_return(
        ['', "fatal: not a git repository\n", failure_status]
      )

      expect { described_class.resolve(context) }.to raise_error(
        RuntimeError, /git rev-parse failed \(exit 1\): fatal: not a git repository/
      )
    end
  end
end
