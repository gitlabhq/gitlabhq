# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe UpdateInvalidMemberStates, feature_category: :subgroups do
  let(:members) { table(:members) }
  let(:groups) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }

  before do
    user = users.create!(first_name: 'Test', last_name: 'User', email: 'test@user.com', projects_limit: 1)
    group = groups.create!(name: 'gitlab', path: 'gitlab-org')
    project = projects.create!(namespace_id: group.id)

    members.create!(state: 2, source_id: group.id, source_type: 'Group', type: 'GroupMember', user_id: user.id, access_level: 50, notification_level: 0)
    members.create!(state: 2, source_id: project.id, source_type: 'Project', type: 'ProjectMember', user_id: user.id, access_level: 50, notification_level: 0)
    members.create!(state: 1, source_id: group.id, source_type: 'Group', type: 'GroupMember', user_id: user.id, access_level: 50, notification_level: 0)
    members.create!(state: 0, source_id: group.id, source_type: 'Group', type: 'GroupMember', user_id: user.id, access_level: 50, notification_level: 0)
  end

  it 'updates matching member record states' do
    expect { migrate! }
      .to change { members.where(state: 0).count }.from(1).to(3)
      .and change { members.where(state: 2).count }.from(2).to(0)
      .and change { members.where(state: 1).count }.by(0)
  end
end
