require 'spec_helper'

describe Gitlab::GithubImport::Importer::PullRequestImporter, :clean_gitlab_redis_cache do
  let(:project) { create(:project, :repository) }
  let(:client) { double(:client) }
  let(:user) { create(:user) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }
  let(:merged_at) { Time.new(2017, 1, 1, 12, 17) }

  let(:source_commit) { project.repository.commit('feature') }
  let(:target_commit) { project.repository.commit('master') }
  let(:milestone) { create(:milestone, project: project) }

  let(:pull_request) do
    alice = Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice')

    Gitlab::GithubImport::Representation::PullRequest.new(
      iid: 42,
      title: 'My Pull Request',
      description: 'This is my pull request',
      source_branch: 'feature',
      source_branch_sha: source_commit.id,
      target_branch: 'master',
      target_branch_sha: target_commit.id,
      source_repository_id: 400,
      target_repository_id: 200,
      source_repository_owner: 'alice',
      state: :closed,
      milestone_number: milestone.iid,
      author: alice,
      assignee: alice,
      created_at: created_at,
      updated_at: updated_at,
      merged_at: merged_at
    )
  end

  let(:importer) { described_class.new(pull_request, project, client) }

  describe '#execute' do
    it 'imports the pull request' do
      expect(importer)
        .to receive(:create_merge_request)
        .and_return(10)

      expect_any_instance_of(Gitlab::GithubImport::IssuableFinder)
        .to receive(:cache_database_id)
        .with(10)

      importer.execute
    end
  end

  describe '#create_merge_request' do
    before do
      allow(importer.milestone_finder)
        .to receive(:id_for)
        .with(pull_request)
        .and_return(milestone.id)
    end

    context 'when the author could be found' do
      before do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(pull_request)
          .and_return([user.id, true])

        allow(importer.user_finder)
          .to receive(:assignee_id_for)
          .with(pull_request)
          .and_return(user.id)
      end

      it 'imports the pull request with the pull request author as the merge request author' do
        expect(Gitlab::GithubImport)
          .to receive(:insert_and_return_id)
          .with(
            {
              iid: 42,
              title: 'My Pull Request',
              description: 'This is my pull request',
              source_project_id: project.id,
              target_project_id: project.id,
              source_branch: 'alice:feature',
              target_branch: 'master',
              state: :merged,
              milestone_id: milestone.id,
              author_id: user.id,
              assignee_id: user.id,
              created_at: created_at,
              updated_at: updated_at
            },
            project.merge_requests
          )
          .and_call_original

        importer.create_merge_request
      end

      it 'returns the ID of the created merge request' do
        id = importer.create_merge_request

        expect(id).to be_a_kind_of(Numeric)
      end

      it 'creates the merge request diffs' do
        importer.create_merge_request

        mr = project.merge_requests.take

        expect(mr.merge_request_diffs.exists?).to eq(true)
      end
    end

    context 'when the author could not be found' do
      it 'imports the pull request with the project creator as the merge request author' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(pull_request)
          .and_return([project.creator_id, false])

        allow(importer.user_finder)
          .to receive(:assignee_id_for)
          .with(pull_request)
          .and_return(user.id)

        expect(Gitlab::GithubImport)
          .to receive(:insert_and_return_id)
          .with(
            {
              iid: 42,
              title: 'My Pull Request',
              description: "*Created by: alice*\n\nThis is my pull request",
              source_project_id: project.id,
              target_project_id: project.id,
              source_branch: 'alice:feature',
              target_branch: 'master',
              state: :merged,
              milestone_id: milestone.id,
              author_id: project.creator_id,
              assignee_id: user.id,
              created_at: created_at,
              updated_at: updated_at
            },
            project.merge_requests
          )
          .and_call_original

        importer.create_merge_request
      end
    end

    context 'when the source and target branch are identical' do
      it 'uses a generated source branch name for the merge request' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(pull_request)
          .and_return([user.id, true])

        allow(importer.user_finder)
          .to receive(:assignee_id_for)
          .with(pull_request)
          .and_return(user.id)

        allow(pull_request)
          .to receive(:source_repository_id)
          .and_return(pull_request.target_repository_id)

        allow(pull_request)
          .to receive(:source_branch)
          .and_return('master')

        expect(Gitlab::GithubImport)
          .to receive(:insert_and_return_id)
          .with(
            {
              iid: 42,
              title: 'My Pull Request',
              description: 'This is my pull request',
              source_project_id: project.id,
              target_project_id: project.id,
              source_branch: 'master-42',
              target_branch: 'master',
              state: :merged,
              milestone_id: milestone.id,
              author_id: user.id,
              assignee_id: user.id,
              created_at: created_at,
              updated_at: updated_at
            },
            project.merge_requests
          )
          .and_call_original

        importer.create_merge_request
      end
    end

    context 'when the import fails due to a foreign key error' do
      it 'does not raise any errors' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(pull_request)
          .and_return([user.id, true])

        allow(importer.user_finder)
          .to receive(:assignee_id_for)
          .with(pull_request)
          .and_return(user.id)

        expect(Gitlab::GithubImport)
          .to receive(:insert_and_return_id)
          .and_raise(ActiveRecord::InvalidForeignKey, 'invalid foreign key')

        expect { importer.create_merge_request }.not_to raise_error
      end
    end
  end
end
