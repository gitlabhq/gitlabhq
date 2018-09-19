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
      mr = double(:merge_request, id: 10)

      expect(importer)
        .to receive(:create_merge_request)
        .and_return([mr, false])

      expect(importer)
        .to receive(:insert_git_data)
        .with(mr, false)

      expect_any_instance_of(Gitlab::GithubImport::IssuableFinder)
        .to receive(:cache_database_id)
        .with(mr.id)

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
        expect(importer)
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

      it 'returns the created merge request' do
        mr, exists = importer.create_merge_request

        expect(mr).to be_instance_of(MergeRequest)
        expect(exists).to eq(false)
      end

      it 'triggers internal_id functionality to track greatest iids' do
        mr = build_stubbed(:merge_request, source_project: project, target_project: project)
        allow(importer).to receive(:insert_and_return_id).and_return(mr.id)
        allow(project.merge_requests).to receive(:find).with(mr.id).and_return(mr)

        expect(mr).to receive(:ensure_target_project_iid!)

        importer.create_merge_request
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

        expect(importer)
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

        expect(importer)
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

        expect(importer)
          .to receive(:insert_and_return_id)
          .and_raise(ActiveRecord::InvalidForeignKey, 'invalid foreign key')

        expect { importer.create_merge_request }.not_to raise_error
      end
    end

    context 'when the merge request already exists' do
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

      it 'returns the existing merge request' do
        mr1, exists1 = importer.create_merge_request
        mr2, exists2 = importer.create_merge_request

        expect(mr2).to eq(mr1)
        expect(exists1).to eq(false)
        expect(exists2).to eq(true)
      end
    end
  end

  describe '#insert_git_data' do
    before do
      allow(importer.milestone_finder)
        .to receive(:id_for)
        .with(pull_request)
        .and_return(milestone.id)

      allow(importer.user_finder)
        .to receive(:author_id_for)
        .with(pull_request)
        .and_return([user.id, true])

      allow(importer.user_finder)
        .to receive(:assignee_id_for)
        .with(pull_request)
        .and_return(user.id)
    end

    it 'creates the merge request diffs' do
      mr, exists = importer.create_merge_request

      importer.insert_git_data(mr, exists)

      expect(mr.merge_request_diffs.exists?).to eq(true)
    end

    it 'creates the merge request diff commits' do
      mr, exists = importer.create_merge_request

      importer.insert_git_data(mr, exists)

      diff = mr.merge_request_diffs.take

      expect(diff.merge_request_diff_commits.exists?).to eq(true)
    end

    context 'when the merge request exists' do
      it 'creates the merge request diffs if they do not yet exist' do
        mr, _ = importer.create_merge_request

        mr.merge_request_diffs.delete_all

        importer.insert_git_data(mr, true)

        expect(mr.merge_request_diffs.exists?).to eq(true)
      end
    end
  end
end
