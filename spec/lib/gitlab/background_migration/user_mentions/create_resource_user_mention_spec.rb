# frozen_string_literal: true

require 'spec_helper'
require './db/post_migrate/20200127131953_migrate_snippet_mentions_to_db'
require './db/post_migrate/20200127151953_migrate_snippet_notes_mentions_to_db'

describe Gitlab::BackgroundMigration::UserMentions::CreateResourceUserMention, schema: 20200127151953 do
  include MigrationsHelpers

  context 'when migrating data' do
    let(:users) { table(:users) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:notes) { table(:notes) }

    let(:author) { users.create!(email: 'author@example.com', notification_email: 'author@example.com', name: 'author', username: 'author', projects_limit: 10, state: 'active') }
    let(:member) { users.create!(email: 'member@example.com', notification_email: 'member@example.com', name: 'member', username: 'member', projects_limit: 10, state: 'active') }
    let(:admin) { users.create!(email: 'administrator@example.com', notification_email: 'administrator@example.com', name: 'administrator', username: 'administrator', admin: 1, projects_limit: 10, state: 'active') }
    let(:john_doe) { users.create!(email: 'john_doe@example.com', notification_email: 'john_doe@example.com', name: 'john_doe', username: 'john_doe', projects_limit: 10, state: 'active') }
    let(:skipped) { users.create!(email: 'skipped@example.com', notification_email: 'skipped@example.com', name: 'skipped', username: 'skipped', projects_limit: 10, state: 'active') }

    let(:mentioned_users) { [author, member, admin, john_doe, skipped] }
    let(:mentioned_users_refs) { mentioned_users.map { |u| "@#{u.username}" }.join(' ') }

    let(:group) { namespaces.create!(name: 'test1', path: 'test1', runners_token: 'my-token1', project_creation_level: 1, visibility_level: 20, type: 'Group') }
    let(:inaccessible_group) { namespaces.create!(name: 'test2', path: 'test2', runners_token: 'my-token2', project_creation_level: 1, visibility_level: 0, type: 'Group') }
    let(:project) { projects.create!(name: 'gitlab1', path: 'gitlab1', namespace_id: group.id, visibility_level: 0) }

    let(:mentioned_groups) { [group, inaccessible_group] }
    let(:group_mentions) { [group, inaccessible_group].map { |gr| "@#{gr.path}" }.join(' ') }
    let(:description_mentions) { "description with mentions #{mentioned_users_refs} and #{group_mentions}" }

    before do
      # build personal namespaces and routes for users
      mentioned_users.each { |u| u.becomes(User).save! }

      # build namespaces and routes for groups
      mentioned_groups.each do |gr|
        gr.name += '-org'
        gr.path += '-org'
        gr.becomes(Namespace).save!
      end
    end

    context 'migrate snippet mentions' do
      let(:snippets) { table(:snippets) }
      let(:snippet_user_mentions) { table(:snippet_user_mentions) }

      let!(:snippet1) { snippets.create!(project_id: project.id, author_id: author.id, title: 'title1', description: description_mentions) }
      let!(:snippet2) { snippets.create!(project_id: project.id, author_id: author.id, title: 'title2', description: 'some description') }
      let!(:snippet3) { snippets.create!(project_id: project.id, author_id: author.id, title: 'title3', description: 'description with an email@example.com and some other @ char here.') }

      let(:user_mentions) { snippet_user_mentions }
      let(:resource) { snippet1 }

      it_behaves_like 'resource mentions migration', MigrateSnippetMentionsToDb, Snippet

      context 'mentions in note' do
        let!(:note1) { notes.create!(noteable_id: snippet1.id, noteable_type: 'Snippet', project_id: project.id, author_id: author.id, note: description_mentions) }
        let!(:note2) { notes.create!(noteable_id: snippet1.id, noteable_type: 'Snippet', project_id: project.id, author_id: author.id, note: 'sample note') }
        let!(:note3) { notes.create!(noteable_id: snippet1.id, noteable_type: 'Snippet', project_id: project.id, author_id: author.id, note: description_mentions, system: true) }
        # this not does not have actual mentions
        let!(:note4) { notes.create!(noteable_id: snippet1.id, noteable_type: 'Snippet', project_id: project.id, author_id: author.id, note: 'note3 for an email@somesite.com and some other rando @ ref' ) }
        # this note points to an innexistent noteable record in snippets table
        let!(:note5) { notes.create!(noteable_id: snippets.maximum(:id) + 10, noteable_type: 'Snippet', project_id: project.id, author_id: author.id, note: description_mentions) }

        it_behaves_like 'resource notes mentions migration', MigrateSnippetNotesMentionsToDb, Snippet
      end
    end
  end

  context 'checks no_quote_columns' do
    it 'has correct no_quote_columns' do
      expect(Gitlab::BackgroundMigration::UserMentions::Models::Snippet.no_quote_columns).to match([:note_id, :snippet_id])
    end
  end
end
