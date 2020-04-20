# frozen_string_literal: true

require 'spec_helper'
require './db/post_migrate/20200128134110_migrate_commit_notes_mentions_to_db'
require './db/post_migrate/20200211155539_migrate_merge_request_mentions_to_db'

describe Gitlab::BackgroundMigration::UserMentions::CreateResourceUserMention, schema: 20200211155539 do
  include MigrationsHelpers

  context 'when migrating data' do
    let(:users) { table(:users) }
    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:notes) { table(:notes) }
    let(:routes) { table(:routes) }

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
      mentioned_users.each do |u|
        namespace = namespaces.create!(path: u.username, name: u.name, runners_token: "my-token-u#{u.id}", owner_id: u.id, type: nil)
        routes.create!(path: namespace.path, source_type: 'Namespace', source_id: namespace.id)
      end

      # build namespaces and routes for groups
      mentioned_groups.each do |gr|
        routes.create!(path: gr.path, source_type: 'Namespace', source_id: gr.id)
      end
    end

    context 'migrate merge request mentions' do
      let(:merge_requests) { table(:merge_requests) }
      let(:merge_request_user_mentions) { table(:merge_request_user_mentions) }

      let!(:mr1) do
        merge_requests.create!(
          title: "title 1", state_id: 1, target_branch: 'feature1', source_branch: 'master',
          source_project_id: project.id, target_project_id: project.id, author_id: author.id,
          description: description_mentions
        )
      end

      let!(:mr2) do
        merge_requests.create!(
          title: "title 2", state_id: 1, target_branch: 'feature2', source_branch: 'master',
          source_project_id: project.id, target_project_id: project.id, author_id: author.id,
          description: 'some description'
        )
      end

      let!(:mr3) do
        merge_requests.create!(
          title: "title 3", state_id: 1, target_branch: 'feature3', source_branch: 'master',
          source_project_id: project.id, target_project_id: project.id, author_id: author.id,
          description: 'description with an email@example.com and some other @ char here.')
      end

      let(:user_mentions) { merge_request_user_mentions }
      let(:resource) { merge_request }

      it_behaves_like 'resource mentions migration', MigrateMergeRequestMentionsToDb, MergeRequest
    end

    context 'migrate commit mentions' do
      let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
      let(:commit) { Commit.new(RepoHelpers.sample_commit, project) }
      let(:commit_user_mentions) { table(:commit_user_mentions) }

      let!(:note1) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: author.id, note: description_mentions) }
      let!(:note2) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: author.id, note: 'sample note') }
      let!(:note3) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: author.id, note: description_mentions, system: true) }

      # this not does not have actual mentions
      let!(:note4) { notes.create!(commit_id: commit.id, noteable_type: 'Commit', project_id: project.id, author_id: author.id, note: 'note for an email@somesite.com and some other random @ ref' ) }
      # this should have pointed to an innexisted commit record in a commits table
      # but because commit is not an AR we'll just make it so that it does not have mentions
      let!(:note5) { notes.create!(commit_id: 'abc', noteable_type: 'Commit', project_id: project.id, author_id: author.id, note: 'note for an email@somesite.com and some other random @ ref') }

      let(:user_mentions) { commit_user_mentions }
      let(:resource) { commit }

      it_behaves_like 'resource notes mentions migration', MigrateCommitNotesMentionsToDb, Commit
    end
  end

  context 'checks no_quote_columns' do
    it 'has correct no_quote_columns' do
      expect(Gitlab::BackgroundMigration::UserMentions::Models::MergeRequest.no_quote_columns).to match([:note_id, :merge_request_id])
    end

    it 'commit has correct no_quote_columns' do
      expect(Gitlab::BackgroundMigration::UserMentions::Models::Commit.no_quote_columns).to match([:note_id])
    end
  end
end
