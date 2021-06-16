# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateCommitNotesMentionsToDb, :migration, :sidekiq do
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

  # non-migrateable resources
  # this note is already migrated, as it has a record in the commit_user_mentions table
  let!(:resource4) { notes.create!(note: 'note3 for @root to check', commit_id: commit.id, noteable_type: 'Commit') }
  let!(:user_mention) { commit_user_mentions.create!(commit_id: commit.id, note_id: resource4.id, mentioned_users_ids: [1]) }
  # this should have pointed to an inexistent commit record in a commits table
  # but because commit is not an AR, we'll just make it so that the note does not have mentions, i.e. no `@` char.
  let!(:resource5) { notes.create!(note: 'note3 to check', commit_id: 'abc', noteable_type: 'Commit') }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it_behaves_like 'schedules resource mentions migration', Commit, true
end
