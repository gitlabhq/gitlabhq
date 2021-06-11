# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveOrphanedInvitedMembers do
  let(:members_table) { table(:members) }
  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }

  let!(:user1) { users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 1) }
  let!(:user2) { users_table.create!(name: 'user2', email: 'user2@example.com', projects_limit: 1) }
  let!(:group) { namespaces_table.create!(type: 'Group', name: 'group', path: 'group') }
  let!(:project) { projects_table.create!(name: 'project', path: 'project', namespace_id: group.id) }

  let!(:member1) { create_member(user_id: user1.id, source_type: 'Project', source_id: project.id, access_level: 10) }
  let!(:member2) { create_member(user_id: user2.id, source_type: 'Group', source_id: group.id, access_level: 20) }

  let!(:invited_member1) do
    create_member(user_id: nil, source_type: 'Project', source_id: project.id,
                  invite_token: SecureRandom.hex, invite_accepted_at: Time.now,
                  access_level: 20)
  end

  let!(:invited_member2) do
    create_member(user_id: nil, source_type: 'Group', source_id: group.id,
                  invite_token: SecureRandom.hex, invite_accepted_at: Time.now,
                  access_level: 20)
  end

  let!(:orphaned_member1) do
    create_member(user_id: nil, source_type: 'Project', source_id: project.id,
                  invite_accepted_at: Time.now, access_level: 30)
  end

  let!(:orphaned_member2) do
    create_member(user_id: nil, source_type: 'Group', source_id: group.id,
                  invite_accepted_at: Time.now, access_level: 20)
  end

  it 'removes orphaned invited members but keeps current members' do
    expect { migrate! }.to change { members_table.count }.from(6).to(4)

    expect(members_table.all.pluck(:id)).to contain_exactly(member1.id, member2.id, invited_member1.id, invited_member2.id)
  end

  def create_member(options)
    members_table.create!(
      {
        notification_level: 0,
        ldap: false,
        override: false
      }.merge(options)
    )
  end
end
