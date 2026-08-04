# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillOrganizationIdOnLegacyAiSettings, migration: :gitlab_main,
  feature_category: :ai_abstraction_layer do
  let(:ai_settings) { table(:ai_settings) }
  let(:organizations) { table(:organizations) }

  let!(:default_organization) do
    organizations.create!(id: described_class::DEFAULT_ORG_ID, name: 'Default', path: 'default')
  end

  describe '#up' do
    context 'when a legacy setting has no organization' do
      let!(:legacy_setting) { ai_settings.create!(organization_id: nil, amazon_q_role_arn: 'legacy-role') }

      it 'assigns it to the default organization' do
        migrate!

        expect(legacy_setting.reload).to have_attributes(
          organization_id: described_class::DEFAULT_ORG_ID,
          amazon_q_role_arn: 'legacy-role'
        )
      end

      context 'when a default organization setting also exists' do
        let!(:default_setting) do
          ai_settings.create!(organization_id: default_organization.id, amazon_q_role_arn: 'default-role')
        end

        it 'preserves the default organization setting and removes the legacy setting' do
          migrate!

          expect(ai_settings.exists?(legacy_setting.id)).to be(false)
          expect(default_setting.reload).to have_attributes(
            organization_id: described_class::DEFAULT_ORG_ID,
            amazon_q_role_arn: 'default-role'
          )
        end
      end
    end

    context 'when all settings already have an organization' do
      let!(:setting) { ai_settings.create!(organization_id: default_organization.id) }

      it 'does not change existing settings' do
        expect { migrate! }.not_to change { setting.reload.attributes }
      end
    end
  end
end
