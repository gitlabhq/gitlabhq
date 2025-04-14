# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetOrganizationIdForBulkImports, migration: :gitlab_main, feature_category: :importers do
  let(:migration) { described_class.new }

  let(:bulk_imports) { table(:bulk_imports) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let!(:user) { users.create!(email: 'user1@example.com', username: 'user1', projects_limit: 100) }

  let!(:default_organization) { organizations.create!(id: 1, path: '/') }

  let!(:custom_organization) { organizations.create!(id: 2, path: '/custom') }

  let!(:bulk_import_with_organization) do
    bulk_imports.create!(organization_id: custom_organization.id, user_id: user.id, source_type: 1, status: 0)
  end

  let!(:bulk_import_without_organization) do
    bulk_imports.create!(organization_id: nil, user_id: user.id, source_type: 1, status: 0)
  end

  describe '#up' do
    it 'updates all bulk_imports that do not have the organization_id set' do
      expect { migrate! }.to change { bulk_import_without_organization.reload.organization_id }.from(nil).to(1)
        .and not_change { bulk_import_with_organization.reload.organization_id }
    end
  end
end
