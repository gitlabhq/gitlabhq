# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../../tooling/ai_harness/doctor/steps/perform_doctor_checks/load_config'

RSpec.describe AiHarness::Doctor::Steps::PerformDoctorChecks::LoadConfig, feature_category: :tooling do
  describe '.load' do
    let(:context) { { results: [] } }

    it 'loads the harness-wide config.yml into context[:config] as a Hash' do
      result = described_class.load(context)

      expect(result[:config]).to be_a(Hash)
    end

    it 'parses allowed_committed_files as a non-empty Array of Strings' do
      result = described_class.load(context)

      allowed = result[:config].fetch('allowed_committed_files')
      expect(allowed).to be_an(Array)
      expect(allowed).not_to be_empty
      expect(allowed).to all(be_a(String))
    end

    it 'returns the context hash' do
      result = described_class.load(context)

      expect(result).to be(context)
    end

    context 'when the config file is missing' do
      before do
        stub_const("#{described_class}::CONFIG_PATH", '/nonexistent/path/config.yml')
      end

      it 'raises (infrastructure error propagates)' do
        expect { described_class.load(context) }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
