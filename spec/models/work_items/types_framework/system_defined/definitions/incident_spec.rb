# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::SystemDefined::Definitions::Incident, feature_category: :team_planning do
  describe '.use_legacy_view?' do
    it 'returns true' do
      expect(described_class.use_legacy_view?).to be(true)
    end
  end

  describe '.incident_management?' do
    it 'returns true' do
      expect(described_class.incident_management?).to be(true)
    end
  end

  describe '.configurable?' do
    it 'returns false' do
      expect(described_class.configurable?).to be(false)
    end
  end

  describe '.filterable?' do
    it 'returns true' do
      expect(described_class.filterable?).to be(true)
    end
  end
end
