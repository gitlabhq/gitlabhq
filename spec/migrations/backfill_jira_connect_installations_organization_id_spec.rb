# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillJiraConnectInstallationsOrganizationId, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:installations) { table(:jira_connect_installations) }
  let(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }

  let(:installation_without_organization) do
    installations.create!(
      client_key: 'foo',
      base_url: 'https://example.com',
      instance_url: 'https://example.com'
    )
  end

  let(:another_installation_without_organization) do
    installations.create!(
      client_key: 'bar',
      base_url: 'https://example.com',
      instance_url: 'https://example.com'
    )
  end

  let(:installation_with_organization) do
    installations.create!(
      client_key: 'baz',
      base_url: 'https://example.com',
      instance_url: 'https://example.com',
      organization_id: organization.id
    )
  end

  before do
    ApplicationRecord
      .connection
      .execute('ALTER TABLE jira_connect_installations DROP CONSTRAINT IF EXISTS check_dc0d039821;')
  end

  after do
    ApplicationRecord
      .connection
      .execute(
        'ALTER TABLE jira_connect_installations ADD CONSTRAINT check_dc0d039821 ' \
          'CHECK ((organization_id IS NOT NULL)) NOT VALID;'
      )
  end

  describe "#up" do
    it 'sets organization_id sharding key for records that do not have it' do
      expect(installation_without_organization.organization_id).to be_nil
      expect(another_installation_without_organization.organization_id).to be_nil
      expect(installation_with_organization.organization_id).to eq(organization.id)

      migrate!

      expect(installation_without_organization.reload.organization_id).to eq(organization.id)
      expect(another_installation_without_organization.reload.organization_id).to eq(organization.id)
      expect(installation_with_organization.reload.organization_id).to eq(organization.id)
    end
  end
end
