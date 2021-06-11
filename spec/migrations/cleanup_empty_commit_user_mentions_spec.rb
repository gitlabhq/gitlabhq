# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupEmptyCommitUserMentions, :migration, :sidekiq do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:notes) { table(:notes) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id) }
  let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }

  let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
  let(:commit) { Commit.new(RepoHelpers.sample_commit, project) }
  let(:commit_user_mentions) { table(:commit_user_mentions) }

  let!(:resource1) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: user.id, note: 'note1 for @root to check') }
  let!(:resource2) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: user.id, note: 'note1 for @root to check') }
  let!(:resource3) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: user.id, note: 'note1 for @root to check', system: true) }

  # this note is already migrated, as it has a record in the commit_user_mentions table
  let!(:resource4) { notes.create!(note: 'note3 for @root to check', commit_id: commit.id, noteable_type: 'Commit') }
  let!(:user_mention) { commit_user_mentions.create!(commit_id: commit.id, note_id: resource4.id, mentioned_users_ids: [1]) }

  # these should get cleanup, by the migration
  let!(:blank_commit_user_mention1) { commit_user_mentions.create!(commit_id: commit.id, note_id: resource1.id)}
  let!(:blank_commit_user_mention2) { commit_user_mentions.create!(commit_id: commit.id, note_id: resource2.id)}
  let!(:blank_commit_user_mention3) { commit_user_mentions.create!(commit_id: commit.id, note_id: resource3.id)}

  it 'cleanups blank user mentions' do
    expect { migrate! }.to change { commit_user_mentions.count }.by(-3)
  end
end
