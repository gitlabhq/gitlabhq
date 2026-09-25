# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Enums::Security, feature_category: :security_testing_configuration do
  describe 'FLOW_BACKED_SCAN_TYPES' do
    it 'lists the scan types executed as an AI flow' do
      expect(described_class::FLOW_BACKED_SCAN_TYPES).to eq(%w[business_logic])
    end

    it 'only lists scan profile types' do
      expect(described_class.scan_profile_types.keys.map(&:to_s)).to include(*described_class::FLOW_BACKED_SCAN_TYPES)
    end
  end
end
