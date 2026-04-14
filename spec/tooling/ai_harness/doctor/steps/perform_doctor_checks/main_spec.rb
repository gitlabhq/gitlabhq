# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/main'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::Main, feature_category: :tooling do
  describe '.main' do
    it 'invokes all sub-chain steps in order' do
      context = { results: [], fix: false }

      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::ResolveRepoRoot)
        .to receive(:resolve).ordered { |ctx| ctx }
      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckParity)
        .to receive(:check).ordered { |ctx| ctx }
      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckAiReferences)
        .to receive(:check).ordered { |ctx| ctx }
      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckGitignore)
        .to receive(:check).ordered { |ctx| ctx }
      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckForbiddenFiles)
        .to receive(:check).ordered { |ctx| ctx }
      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::FormatOutput)
        .to receive(:format).ordered { |ctx| ctx.merge(stdout_text: 'output') }
      expect(AiHarness::Doctor::Steps::PerformDoctorChecks::DetermineExitCode)
        .to receive(:determine).ordered { |ctx| ctx.merge(exit_code: 0) }

      result = described_class.main(context)

      expect(result).to include(stdout_text: 'output', exit_code: 0)
    end

    it 'returns the context hash (not a Result)' do
      context = { results: [], fix: false }

      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::ResolveRepoRoot).to receive(:resolve) { |ctx| ctx }
      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckParity).to receive(:check) { |ctx| ctx }
      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckAiReferences).to receive(:check) { |ctx| ctx }
      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckGitignore).to receive(:check) { |ctx| ctx }
      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::CheckForbiddenFiles).to receive(:check) { |ctx| ctx }
      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::FormatOutput).to receive(:format) { |ctx| ctx }
      allow(AiHarness::Doctor::Steps::PerformDoctorChecks::DetermineExitCode).to receive(:determine) { |ctx| ctx }

      result = described_class.main(context)

      expect(result).to be_a(Hash)
    end
  end
end
