# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequestImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(
      :project, :repository, :in_group, :github_import,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled
    )
  end

  let_it_be(:user_representation_1) { Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice') }
  let_it_be(:user_representation_2) { Gitlab::GithubImport::Representation::User.new(id: 5, login: 'bob') }
  let_it_be(:source_user_1) { generate_source_user(project, user_representation_1.id) }
  let_it_be(:source_user_2) { generate_source_user(project, user_representation_2.id) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double(Gitlab::GithubImport::Client, web_endpoint: 'https://github.com') }
  let(:created_at) { DateTime.strptime('2024-11-05T20:10:15Z') }
  let(:updated_at) { DateTime.strptime('2024-11-06T20:10:15Z') }
  let(:merged_at) { DateTime.strptime('2024-11-07T20:10:15Z') }

  let(:source_commit) { project.repository.commit('feature') }
  let(:target_commit) { project.repository.commit('master') }
  let(:milestone) { create(:milestone, project: project) }
  let(:description) { 'This is my pull request' }
  let(:state) { :closed }

  let(:pull_request_attributes) do
    {
      iid: 42,
      title: 'My Pull Request',
      description: description,
      source_branch: 'feature',
      source_branch_sha: source_commit.id,
      target_branch: 'master',
      target_branch_sha: target_commit.id,
      source_repository_id: 400,
      target_repository_id: 200,
      source_repository_owner: user_representation_1.login,
      state: state,
      milestone_number: milestone.iid,
      author: user_representation_1,
      assignee: user_representation_2,
      created_at: created_at,
      updated_at: updated_at,
      merged_at: state == :closed && merged_at
    }
  end

  let(:pull_request) { Gitlab::GithubImport::Representation::PullRequest.new(pull_request_attributes) }
  let(:user_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  let(:importer) { described_class.new(pull_request, project, client) }

  describe '#execute', :aggregate_failures do
    it 'imports the pull request and assignees' do
      expect(importer).to receive(:insert_git_data)

      expect { importer.execute }.to change { MergeRequest.count }.from(0).to(1)

      created_merge_request = MergeRequest.last
      created_mr_assignees = created_merge_request.assignees

      expect(created_merge_request.author_id).to eq(source_user_1.mapped_user_id)
      expect(created_mr_assignees).to match_array([source_user_2.mapped_user])

      expect(created_merge_request).to have_attributes(
        iid: pull_request.iid,
        title: pull_request.truncated_title,
        description: description,
        source_project_id: project.id,
        target_project_id: project.id,
        source_branch: pull_request.formatted_source_branch,
        target_branch: pull_request.target_branch,
        state_id: MergeRequest.available_states[:merged],
        milestone_id: milestone.id,
        author_id: source_user_1.mapped_user_id,
        created_at: created_at,
        updated_at: updated_at,
        imported_from: Import::SOURCE_GITHUB.to_s
      )
    end

    it 'caches the created MR ID even if importer later fails' do
      mr = create(:merge_request, :merged, author: user)
      error = StandardError.new('mocked error')

      allow_next_instance_of(described_class) do |importer|
        allow(importer)
          .to receive(:create_merge_request)
          .and_return([mr, false])
        allow(importer)
          .to receive(:set_merge_request_assignees)
          .and_raise(error)
      end

      expect_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        expect(finder)
          .to receive(:cache_database_id)
          .with(mr.id)
      end

      expect { importer.execute }.to raise_error(error)
    end

    it 'pushes placeholder references to the store' do
      importer.execute
      created_merge_request = MergeRequest.last
      created_mr_assignee = created_merge_request.merge_request_assignees.first # we only import one PR assignee

      expect(user_references).to match_array([
        ['MergeRequest', created_merge_request.id, 'author_id', source_user_1.id],
        ['MergeRequestAssignee', created_mr_assignee.id, 'user_id', source_user_2.id]
      ])
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }

      before_all do
        project.update!(namespace: user_namespace)
      end

      it 'does not push any references' do
        importer.execute

        expect(user_references).to be_empty
      end

      it 'imports the pull request mapped to the personal namespace owner' do
        expect { importer.execute }.to change { MergeRequest.count }.from(0).to(1)

        created_merge_request = MergeRequest.last
        expect(created_merge_request.author_id).to eq(user_namespace.owner_id)
        expect(created_merge_request.assignee_ids).to contain_exactly(user_namespace.owner_id)
      end

      context 'when user_mapping_to_personal_namespace_owner is disabled' do
        let_it_be(:source_user_1) { generate_source_user(project, user_representation_1.id) }
        let_it_be(:source_user_2) { generate_source_user(project, user_representation_2.id) }

        before_all do
          project.build_or_assign_import_data(
            data: { user_mapping_to_personal_namespace_owner_enabled: false }
          ).save!
        end

        it 'pushes placeholder references' do
          importer.execute

          created_merge_request = MergeRequest.last
          created_mr_assignee = created_merge_request.merge_request_assignees.first

          expect(user_references).to match_array([
            ['MergeRequest', created_merge_request.id, 'author_id', source_user_1.id],
            ['MergeRequestAssignee', created_mr_assignee.id, 'user_id', source_user_2.id]
          ])
        end

        it 'imports the pull request mapped to the placeholder users' do
          expect { importer.execute }.to change { MergeRequest.count }.from(0).to(1)

          created_merge_request = MergeRequest.last
          expect(created_merge_request.author_id).to eq(source_user_1.mapped_user_id)
          expect(created_merge_request.assignee_ids).to contain_exactly(source_user_2.mapped_user_id)
        end
      end
    end

    context 'when the description is processed for formatting' do
      let(:description) { "I said to @sam_allen\0 the code should follow @bob's\0 advice. @.ali-ce/group#9?\0" }
      let(:expected_description) do
        "I said to `@sam_allen` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?"
      end

      before do
        allow(Gitlab::GithubImport::MarkdownText).to receive(:format).and_call_original

        importer.execute
      end

      it 'verify that the formatted description using MarkdownText equals the expected description' do
        expect(Gitlab::GithubImport::MarkdownText).to have_received(:format)
        expect(MergeRequest.last.description).to eq(expected_description)
      end
    end

    context 'when the pull request does not have assignees' do
      it 'creates a merge request without assignees' do
        pull_request_attributes[:assignee] = nil

        expect { importer.execute }.to change { MergeRequest.count }.from(0).to(1)

        created_merge_request = MergeRequest.last

        expect(created_merge_request.assignees).to be_empty
      end
    end

    context 'when the source and target branch are identical' do
      it 'uses a generated source branch name for the merge request' do
        pull_request_attributes[:source_repository_id] = pull_request_attributes[:target_repository_id]
        pull_request_attributes[:source_branch] = pull_request_attributes[:target_branch]

        importer.execute

        expect(MergeRequest.last.source_branch).to eq('master-42')
      end
    end

    context 'when the merge request is invalid' do
      it 'does not create a duplicate merge request when it has already been created' do
        expect { 2.times { importer.execute } }.to change { MergeRequest.count }.from(0).to(1)
      end

      it 'skips creating a merge request without error when a foreign key error is raised' do
        allow(importer).to receive(:insert_and_return_id)
          .and_raise(ActiveRecord::InvalidForeignKey, 'invalid foreign key')

        expect { importer.execute }.not_to change { MergeRequest.count }
      end

      it 'raises all other exceptions and does not create a merge request' do
        allow(pull_request).to receive(:formatted_source_branch).and_return(nil)

        expect { importer.execute }.to raise_error(ActiveRecord::RecordInvalid)
          .and not_change { MergeRequest.count }
      end
    end

    context 'with git data' do
      before do
        allow(importer.milestone_finder)
          .to receive(:id_for)
          .with(pull_request)
          .and_return(milestone.id)
      end

      it 'does not create the source branch if merge request is merged' do
        importer.execute
        mr = MergeRequest.last

        expect(project.repository.branch_exists?(mr.source_branch)).to be_falsey
        expect(project.repository.branch_exists?(mr.target_branch)).to be_truthy
      end

      it 'creates a merge request diff and sets it as the latest' do
        importer.execute
        mr = MergeRequest.last

        expect(mr.merge_request_diffs.exists?).to eq(true)
        expect(mr.reload.latest_merge_request_diff_id).to eq(mr.merge_request_diffs.first.id)
      end

      it 'creates the merge request diff commits' do
        importer.execute
        mr = MergeRequest.last

        diff = mr.merge_request_diffs.reload.first

        expect(diff.merge_request_diff_commits.exists?).to eq(true)
      end

      context 'when merge request is open' do
        let(:project) { create(:project, :repository, :in_group, :github_import, :import_user_mapping_enabled) }
        let(:state) { :opened }

        before do
          allow(client).to receive(:user).and_return({ name: 'Github user name' })
        end

        it 'creates the source branch' do
          importer.execute
          mr = MergeRequest.last

          expect(project.repository.branch_exists?(mr.source_branch)).to be_truthy
          expect(project.repository.branch_exists?(mr.target_branch)).to be_truthy
        end

        it 'is able to retry on pre-receive errors' do
          expect(importer).to receive(:insert_or_replace_git_data).twice.and_call_original
          allow(project.repository).to receive(:add_branch).and_raise('exception')

          expect { importer.execute }.to raise_error('exception')

          expect(project.repository).to receive(:add_branch).with(project.creator, anything, anything).and_call_original

          importer.execute
          mr = MergeRequest.last

          expect(project.repository.branch_exists?(mr.source_branch)).to be_truthy
          expect(project.repository.branch_exists?(mr.target_branch)).to be_truthy
          expect(mr.merge_request_diffs).to be_one
        end

        it 'ignores Git command errors when creating a branch' do
          allow(project.repository).to receive(:add_branch).and_raise(Gitlab::Git::CommandError)
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          importer.execute
          mr = MergeRequest.last

          expect(project.repository.branch_exists?(mr.source_branch)).to be_falsey
          expect(project.repository.branch_exists?(mr.target_branch)).to be_truthy
        end

        it 'ignores Git PreReceive errors when creating a branch' do
          allow(project.repository).to receive(:add_branch).and_raise(Gitlab::Git::PreReceiveError)
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          importer.execute
          mr = MergeRequest.last

          expect(project.repository.branch_exists?(mr.source_branch)).to be_falsey
          expect(project.repository.branch_exists?(mr.target_branch)).to be_truthy
        end
      end

      context 'when the merge request exists' do
        it 'creates the merge request diffs if they do not yet exist' do
          importer.execute
          mr = MergeRequest.last

          mr.merge_request_diff.destroy!

          importer.execute

          expect(mr.merge_request_diffs.exists?).to eq(true)
        end
      end
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      context 'when author and assignee are found' do
        let_it_be(:user_2) { create(:user) }

        before do
          allow(importer.user_finder)
            .to receive(:find)
            .with(user_representation_1.id, user_representation_1.login)
            .and_return(user.id)

          allow(importer.user_finder)
            .to receive(:find)
            .with(user_representation_2.id, user_representation_2.login)
            .and_return(user_2.id)
        end

        it 'imports the merge request with gitlab matching gitlab author and assignee' do
          expect { importer.execute }.to change { MergeRequest.count }.from(0).to(1)
            .and not_change { User.where(user_type: :placeholder).count }

          created_merge_request = MergeRequest.last

          expect(created_merge_request.author.id).to eq(user.id)
          expect(created_merge_request.assignees.first.id).to eq(user_2.id) # we only import one PR assignee
        end

        it 'does not push any placeholder references' do
          importer.execute

          expect(user_references).to be_empty
        end
      end

      context 'when author and assignee are not found' do
        before do
          allow(importer.user_finder)
            .to receive(:find)
            .with(user_representation_1.id, user_representation_1.login)
            .and_return(nil)

          allow(importer.user_finder)
            .to receive(:find)
            .with(user_representation_2.id, user_representation_2.login)
            .and_return(nil)
        end

        it 'imports the merge request with the project creator as the author' do
          expect { importer.execute }.to change { MergeRequest.count }.from(0).to(1)
            .and not_change { User.where(user_type: :placeholder).count }

          expect(MergeRequest.last.author.id).to eq(project.creator_id)
        end

        it 'does not assign assignees that were not found' do
          expect { importer.execute }.not_to change { MergeRequestAssignee.count }
        end

        it 'does not push any placeholder references' do
          importer.execute

          expect(user_references).to be_empty
        end
      end
    end
  end
end
