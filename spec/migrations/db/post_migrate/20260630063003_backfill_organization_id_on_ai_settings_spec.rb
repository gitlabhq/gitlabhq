# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillOrganizationIdOnAiSettings, migration: :gitlab_main, feature_category: :ai_abstraction_layer do
  let(:ai_settings) { table(:ai_settings) }
  let(:organizations) { table(:organizations) }

  let!(:default_organization) do
    organizations.create!(id: described_class::DEFAULT_ORG_ID, name: 'Default', path: 'default')
  end

  describe '#up' do
    context 'when organization_id is NULL' do
      let!(:ai_setting) { ai_settings.create!(organization_id: nil) }

      it 'backfills organization_id with the default organization id' do
        migrate!

        expect(ai_setting.reload.organization_id).to eq(described_class::DEFAULT_ORG_ID)
      end
    end

    context 'when organization_id is already set' do
      let!(:other_organization) { organizations.create!(name: 'Other', path: 'other') }
      let!(:ai_setting) { ai_settings.create!(organization_id: other_organization.id) }

      it 'leaves the existing organization_id unchanged' do
        migrate!

        expect(ai_setting.reload.organization_id).to eq(other_organization.id)
      end
    end
  end
end
