# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveInvalidWebhookRecords, feature_category: :webhooks do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }
  let(:web_hooks) { table(:web_hooks) }

  let!(:default_organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:namespace) { namespaces.create!(name: 'test-namespace', path: 'test-namespace', organization_id: 1) }
  let!(:project) do
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: 1)
  end

  let!(:integration) do
    integrations.create!(
      instance: false,
      project_id: project.id,
      type_new: 'Integrations::MockCi'
    )
  end

  describe '#up' do
    context 'when there are invalid webhook records' do
      # Create invalid webhooks using raw SQL to bypass future sharding key constraints
      let!(:invalid_webhook_1_id) do
        ActiveRecord::Base.connection.execute(
          "INSERT INTO web_hooks (name, type, project_id, group_id, organization_id, integration_id, created_at,
           updated_at) VALUES ('invalid-hook-1', 'ProjectHook', NULL, NULL, NULL, NULL, NOW(), NOW()) RETURNING id"
        ).first['id']
      end

      let!(:invalid_webhook_2_id) do
        ActiveRecord::Base.connection.execute(
          "INSERT INTO web_hooks (name, type, project_id, group_id, organization_id, integration_id, created_at,
           updated_at) VALUES ('invalid-hook-2', 'GroupHook', NULL, NULL, NULL, NULL, NOW(), NOW()) RETURNING id"
        ).first['id']
      end

      it 'removes webhook records with all foreign keys as null' do
        expect { migrate! }.to change { web_hooks.count }.by(-2)

        expect(web_hooks.where(id: [invalid_webhook_1_id, invalid_webhook_2_id])).to be_empty
      end
    end

    context 'when there are valid webhook records that should NOT be removed' do
      let!(:project_webhook) do
        web_hooks.create!(
          name: 'project-hook',
          type: 'ProjectHook',
          project_id: project.id,
          group_id: nil,
          organization_id: nil,
          integration_id: nil
        )
      end

      let!(:group_webhook) do
        web_hooks.create!(
          name: 'group-hook',
          type: 'GroupHook',
          project_id: nil,
          group_id: namespace.id,
          organization_id: nil,
          integration_id: nil
        )
      end

      let!(:organization_webhook) do
        web_hooks.create!(
          name: 'org-hook',
          type: 'SystemHook',
          project_id: nil,
          group_id: nil,
          organization_id: default_organization.id,
          integration_id: nil
        )
      end

      let!(:integration_webhook) do
        web_hooks.create!(
          name: 'integration-hook',
          type: 'ServiceHook',
          project_id: nil,
          group_id: nil,
          organization_id: nil,
          integration_id: integration.id
        )
      end

      it 'does not remove webhook records with at least one non-null foreign key' do
        expect { migrate! }.not_to change { web_hooks.count }

        # Verify all valid webhooks are still present
        expect(web_hooks.find(project_webhook.id)).to be_present
        expect(web_hooks.find(group_webhook.id)).to be_present
        expect(web_hooks.find(organization_webhook.id)).to be_present
        expect(web_hooks.find(integration_webhook.id)).to be_present
      end

      it 'preserves webhook attributes correctly' do
        migrate!

        reloaded_project_webhook = web_hooks.find(project_webhook.id)
        expect(reloaded_project_webhook).to have_attributes(
          name: 'project-hook',
          type: 'ProjectHook',
          project_id: project.id,
          group_id: nil,
          organization_id: nil,
          integration_id: nil
        )

        reloaded_group_webhook = web_hooks.find(group_webhook.id)
        expect(reloaded_group_webhook).to have_attributes(
          name: 'group-hook',
          type: 'GroupHook',
          project_id: nil,
          group_id: namespace.id,
          organization_id: nil,
          integration_id: nil
        )

        reloaded_organization_webhook = web_hooks.find(organization_webhook.id)
        expect(reloaded_organization_webhook).to have_attributes(
          name: 'org-hook',
          type: 'SystemHook',
          project_id: nil,
          group_id: nil,
          organization_id: default_organization.id,
          integration_id: nil
        )

        reloaded_integration_webhook = web_hooks.find(integration_webhook.id)
        expect(reloaded_integration_webhook).to have_attributes(
          name: 'integration-hook',
          type: 'ServiceHook',
          project_id: nil,
          group_id: nil,
          organization_id: nil,
          integration_id: integration.id
        )
      end
    end

    context 'when there are both valid and invalid webhook records' do
      let!(:valid_webhook) do
        web_hooks.create!(
          name: 'valid-hook',
          type: 'ProjectHook',
          project_id: project.id,
          group_id: nil,
          organization_id: nil,
          integration_id: nil
        )
      end

      let!(:invalid_webhook_id) do
        ActiveRecord::Base.connection.execute(
          "INSERT INTO web_hooks (name, type, project_id, group_id, organization_id, integration_id, created_at,
           updated_at) VALUES ('invalid-hook', 'ProjectHook', NULL, NULL, NULL, NULL, NOW(), NOW()) RETURNING id"
        ).first['id']
      end

      it 'removes only the invalid webhook records' do
        expect { migrate! }.to change { web_hooks.count }.by(-1)

        expect(web_hooks.find_by(id: valid_webhook.id)).to be_present
        expect(web_hooks.find_by(id: invalid_webhook_id)).to be_nil
      end
    end

    context 'when there are no webhook records' do
      it 'does not raise an error' do
        expect { migrate! }.not_to raise_error
        expect(web_hooks.count).to eq(0)
      end
    end

    context 'when there are no invalid webhook records' do
      let!(:valid_webhook) do
        web_hooks.create!(
          name: 'valid-hook',
          type: 'ProjectHook',
          project_id: project.id,
          group_id: nil,
          organization_id: nil,
          integration_id: nil
        )
      end

      it 'does not remove any records' do
        expect { migrate! }.not_to change { web_hooks.count }
        expect(web_hooks.find(valid_webhook.id)).to be_present
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { described_class.new.down }.not_to raise_error
    end
  end
end
