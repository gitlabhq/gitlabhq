# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RemoveShimoZentaoIntegrationRecords, feature_category: :integrations do
  let(:integrations) { table(:integrations) }
  let(:zentao_tracker_data) { table(:zentao_tracker_data) }

  before do
    integrations.create!(id: 1, type_new: 'Integrations::MockMonitoring')
    integrations.create!(id: 2, type_new: 'Integrations::Redmine')
    integrations.create!(id: 3, type_new: 'Integrations::Confluence')

    integrations.create!(id: 4, type_new: 'Integrations::Shimo')
    integrations.create!(id: 5, type_new: 'Integrations::Zentao')
    integrations.create!(id: 6, type_new: 'Integrations::Zentao')
    zentao_tracker_data.create!(id: 1, integration_id: 5)
    zentao_tracker_data.create!(id: 2, integration_id: 6)
  end

  context 'with CE/EE env' do
    it 'destroys all shimo and zentao integrations' do
      migrate!

      expect(integrations.count).to eq(3) # keep other integrations
      expect(integrations.where(type_new: described_class::TYPES).count).to eq(0)
      expect(zentao_tracker_data.count).to eq(0)
    end
  end

  context 'with JiHu env' do
    before do
      allow(Gitlab).to receive(:jh?).and_return(true)
    end

    it 'keeps shimo and zentao integrations' do
      migrate!

      expect(integrations.count).to eq(6)
      expect(integrations.where(type_new: described_class::TYPES).count).to eq(3)
      expect(zentao_tracker_data.count).to eq(2)
    end
  end
end
