# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupRecordsWithNullNamespaceIdFromSeatAssignments, migration: :gitlab_main, feature_category: :seat_cost_management do
  let(:migration) { described_class.new }
  let(:seat_assignments) { table(:subscription_seat_assignments) }

  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:user) { table(:users).create!(email: 'user@example.com', username: 'user', projects_limit: 10) }
  let(:namespace) do
    table(:namespaces).create!(name: 'group', path: 'group', type: 'Group', organization_id: organization.id)
  end

  describe '#down' do
    before do
      seat_assignments.create!(namespace_id: namespace.id, user_id: user.id, organization_id: organization.id)
      seat_assignments.create!(namespace_id: nil, user_id: user.id, organization_id: organization.id)
    end

    it 'removes records with nil namespace_id' do
      expect { migration.down }
        .to change { seat_assignments.count }.from(2).to(1)
        .and not_change { seat_assignments.where.not(namespace_id: nil).count }
    end
  end
end
