# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200127131953_migrate_snippet_mentions_to_db')

describe MigrateSnippetMentionsToDb, :migration, :sidekiq do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:snippets) { table(:snippets) }
  let(:snippet_user_mentions) { table(:snippet_user_mentions) }

  let(:user) { users.create!(name: 'root', email: 'root@example.com', username: 'root', projects_limit: 0) }
  let(:group) { namespaces.create!(name: 'group1', path: 'group1', owner_id: user.id) }
  let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }
  let!(:resource1) { snippets.create!(title: "title1", title_html: 'title1', description: 'snippet description with @root mention', project_id: project.id, author_id: user.id) }
  let!(:resource2) { snippets.create!(title: "title2", title_html: "title2", description: 'snippet description with @group mention', project_id: project.id, author_id: user.id) }
  let!(:resource3) { snippets.create!(title: "title3", title_html: "title3", description: 'snippet description with @project mention', project_id: project.id, author_id: user.id) }

  # non-migrateable resources
  # this snippet is already migrated, as it has a record in the snippet_user_mentions table
  let!(:resource4) { snippets.create!(title: "title4", title_html: "title4", description: 'snippet description with @project mention', project_id: project.id, author_id: user.id) }
  let!(:user_mention) { snippet_user_mentions.create!(snippet_id: resource4.id, mentioned_users_ids: [1]) }
  # this snippet has no mentions so should be filtered out
  let!(:resource5) { snippets.create!(title: "title5", title_html: "title5", description: 'snippet description with no mention', project_id: project.id, author_id: user.id) }

  it_behaves_like 'schedules resource mentions migration', Snippet, false
end
