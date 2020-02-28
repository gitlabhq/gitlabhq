# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200127151953_migrate_snippet_notes_mentions_to_db')

describe MigrateSnippetNotesMentionsToDb, :migration, :sidekiq do
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:snippets) { table(:snippets) }
  let(:snippet_user_mentions) { table(:snippet_user_mentions) }
  let(:notes) { table(:notes) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id) }
  let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }
  let(:snippet) { snippets.create!(title: "title1", title_html: 'title1', description: 'snippet description with @root mention', project_id: project.id, author_id: user.id) }

  let!(:resource1) { notes.create!(note: 'note for @root to check', noteable_id: snippet.id, noteable_type: 'Snippet') }
  let!(:resource2) { notes.create!(note: 'note for @root to check', noteable_id: snippet.id, noteable_type: 'Snippet', system: true) }
  let!(:resource3) { notes.create!(note: 'note for @root to check', noteable_id: snippet.id, noteable_type: 'Snippet') }

  # non-migrateable resources
  # this note is already migrated, as it has a record in the snippet_user_mentions table
  let!(:resource4) { notes.create!(note: 'note for @root to check', noteable_id: snippet.id, noteable_type: 'Snippet') }
  let!(:user_mention) { snippet_user_mentions.create!(snippet_id: snippet.id, note_id: resource4.id, mentioned_users_ids: [1]) }
  # this note points to an innexistent noteable record
  let!(:resource5) { notes.create!(note: 'note for @root to check', noteable_id: snippets.maximum(:id) + 10, noteable_type: 'Snippet') }

  it_behaves_like 'schedules resource mentions migration', Snippet, true
end
