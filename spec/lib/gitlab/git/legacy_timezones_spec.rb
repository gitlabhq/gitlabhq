# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::LegacyTimezones, feature_category: :source_code_management do
  describe 'MAPPING' do
    it 'maps legacy links directly to canonical zones' do
      expect(described_class::MAPPING.values & described_class::MAPPING.keys).to be_empty
    end

    it 'maps to zones that exist' do
      expect(described_class::MAPPING.values - TZInfo::Timezone.all_identifiers).to be_empty
    end
  end
end
