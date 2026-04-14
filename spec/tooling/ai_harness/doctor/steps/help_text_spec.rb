# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/ai_harness/doctor/steps/help_text'

RSpec.describe AiHarness::Doctor::Steps::HelpText, feature_category: :tooling do
  describe '.help' do
    it 'returns a string containing Usage, --fix, and --help' do
      text = described_class.help

      expect(text).to include('Usage:')
      expect(text).to include('--fix')
      expect(text).to include('--help')
    end
  end
end
