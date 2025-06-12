# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AssignOrganizationToPlaceholderUsers, feature_category: :organization do
  let(:organization_users) { table(:organization_users) }
  let(:users) { table(:users) }
  let(:user_type) { HasUserType::USER_TYPES[:placeholder] }

  let!(:organization) { table(:organizations).create!(id: 1, name: 'MyOrg', path: 'my-org') }
  let!(:valid_user) do
    table(:users).create!(user_type: user_type, email: 'a@example.com', projects_limit: 10)
  end

  let!(:org_user) { organization_users.create!(user_id: valid_user.id, organization_id: organization.id) }
  let!(:invalid_user) do
    table(:users).create!(user_type: user_type, email: 'b@example.com', projects_limit: 10)
  end

  def organizations(user_id)
    ApplicationRecord.connection.exec_query(
      "SELECT organization_id, user_id, created_at, updated_at FROM organization_users WHERE user_id = $1",
      "SQL",
      [user_id]
    ).flat_map(&:values)
  end

  describe '#up' do
    subject(:perform_migration) { migrate! }

    it 'assigns organization with id=1 if user does not have a record' do
      expect { perform_migration }.to change { organizations(invalid_user.id).first }.from(nil).to(1)
    end

    it 'does not change the record for the valid user' do
      expect { perform_migration }.not_to change { organizations(valid_user.id) }
    end
  end
end
