# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateAllMergeRequestUserMentionsToDb, :migration do
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:merge_requests) { table(:merge_requests) }
  let(:merge_request_user_mentions) { table(:merge_request_user_mentions) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id, type: 'Group') }
  let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }

  let(:opened_state) { 1 }
  let(:closed_state) { 2 }
  let(:merged_state) { 3 }

  # migrateable resources
  let(:common_args) { { source_branch: 'master', source_project_id: project.id, target_project_id: project.id, author_id: user.id, description: 'mr description with @root mention' } }
  let!(:resource1) { merge_requests.create!(common_args.merge(title: "title 1", state_id: opened_state, target_branch: 'feature1')) }
  let!(:resource2) { merge_requests.create!(common_args.merge(title: "title 2", state_id: closed_state, target_branch: 'feature2')) }
  let!(:resource3) { merge_requests.create!(common_args.merge(title: "title 3", state_id: merged_state, target_branch: 'feature3')) }

  # non-migrateable resources
  # this merge request is already migrated, as it has a record in the merge_request_user_mentions table
  let!(:resource4) { merge_requests.create!(common_args.merge(title: "title 3", state_id: opened_state, target_branch: 'feature4')) }
  let!(:user_mention) { merge_request_user_mentions.create!(merge_request_id: resource4.id, mentioned_users_ids: [1]) }

  let!(:resource5) { merge_requests.create!(common_args.merge(title: "title 3", description: 'description with no mention', state_id: opened_state, target_branch: 'feature5')) }

  it_behaves_like 'schedules resource mentions migration', MergeRequest, false
end
