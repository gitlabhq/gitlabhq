# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Instance::Integration, feature_category: :integrations do
  subject(:instance_integration) { build(:instance_integration) }

  describe '#instance_level?' do
    it 'returns true' do
      expect(instance_integration.instance_level?).to be(true)
    end
  end

  describe '#group_level?' do
    it 'returns false' do
      expect(instance_integration.group_level?).to be(false)
    end
  end

  describe '#project_level?' do
    it 'returns false' do
      expect(instance_integration.project_level?).to be(false)
    end
  end

  describe '.table_name' do
    it 'returns instance_integrations' do
      expect(described_class.table_name).to eq('instance_integrations')
    end
  end
end
