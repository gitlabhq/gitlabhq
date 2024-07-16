# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::PullRequestImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:bitbucket_user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:user_3) { create(:user) }
  let_it_be(:closed_by_user) { create(:user) }
  let_it_be(:identity) { create(:identity, user: bitbucket_user, extern_uid: '{123}', provider: :bitbucket) }
  let_it_be(:identity_2) { create(:identity, user: user_2, extern_uid: 'user_2', provider: :bitbucket) }
  let_it_be(:closed_by_identity) { create(:identity, user: closed_by_user, extern_uid: '{345}', provider: :bitbucket) }
  let(:mentions_converter) { Gitlab::Import::MentionsConverter.new('bitbucket', project) }
  let(:source_branch_sha) { project.repository.commit.sha }
  let(:target_branch_sha) { project.repository.commit('refs/heads/master').sha }

  let(:hash) do
    {
      author: '{123}',
      author_nickname: 'bitbucket_user',
      created_at: Date.today,
      description: 'description',
      iid: 11,
      source_branch_name: 'source-branch-name',
      source_branch_sha: source_branch_sha,
      state: 'merged',
      target_branch_name: 'destination-branch-name',
      target_branch_sha: target_branch_sha,
      title: 'title',
      updated_at: Date.today,
      reviewers: %w[user_2 user_3],
      closed_by: '{345}'
    }
  end

  subject(:importer) { described_class.new(project, hash) }

  before do
    allow(Gitlab::Import::MentionsConverter).to receive(:new).and_return(mentions_converter)
  end

  describe '#execute' do
    it 'calls MergeRequestCreator' do
      expect(Gitlab::Import::MergeRequestCreator).to receive_message_chain(:new, :execute)

      importer.execute
    end

    it 'creates a merge request with the correct attributes' do
      expect { importer.execute }.to change { project.merge_requests.count }.from(0).to(1)

      merge_request = project.merge_requests.first

      expect(merge_request.iid).to eq(11)
      expect(merge_request.author).to eq(bitbucket_user)
      expect(merge_request.title).to eq('title')
      expect(merge_request.merged?).to be_truthy
      expect(merge_request.created_at).to eq(Date.today)
      expect(merge_request.description).to eq('description')
      expect(merge_request.source_project_id).to eq(project.id)
      expect(merge_request.target_project_id).to eq(project.id)
      expect(merge_request.source_branch).to eq('source-branch-name')
      expect(merge_request.target_branch).to eq('destination-branch-name')
      expect(merge_request.assignee_ids).to eq([bitbucket_user.id])
      expect(merge_request.reviewer_ids).to eq([user_2.id])
      expect(merge_request.merge_request_diffs.first.base_commit_sha).to eq(source_branch_sha)
      expect(merge_request.merge_request_diffs.first.head_commit_sha).to eq(target_branch_sha)
      expect(merge_request.metrics.merged_by_id).to eq(closed_by_user.id)
      expect(merge_request.metrics.latest_closed_by_id).to be_nil
      expect(merge_request.imported_from).to eq('bitbucket')
    end

    it 'converts mentions in the description' do
      expect(mentions_converter).to receive(:convert).once.and_call_original

      importer.execute
    end

    context 'when the state is closed' do
      it 'marks merge request as closed' do
        described_class.new(project, hash.merge(state: 'closed')).execute

        expect(project.merge_requests.first.closed?).to be_truthy
        expect(project.merge_requests.first.metrics.latest_closed_by_id).to eq(closed_by_user.id)
        expect(project.merge_requests.first.metrics.merged_by_id).to be_nil
      end
    end

    context 'when the state is opened' do
      it 'marks merge request as opened' do
        described_class.new(project, hash.merge(state: 'opened')).execute

        expect(project.merge_requests.first.opened?).to be_truthy
        expect(project.merge_requests.first.metrics.latest_closed_by_id).to be_nil
        expect(project.merge_requests.first.metrics.merged_by_id).to be_nil
      end
    end

    context 'when the source and target projects are different' do
      let(:importer) { described_class.new(project, hash.merge(source_and_target_project_different: true)) }

      it 'skips the import' do
        expect(Gitlab::BitbucketImport::Logger)
          .to receive(:info)
          .with(include(message: 'skipping because source and target projects are different', iid: anything))

        expect { importer.execute }.not_to change { project.merge_requests.count }
      end
    end

    context 'when the author does not have a bitbucket identity' do
      before do
        identity.update!(provider: :github)
      end

      it 'sets the author and assignee to the project creator and adds the author to the description' do
        importer.execute

        merge_request = project.merge_requests.first

        expect(merge_request.author).to eq(project.creator)
        expect(merge_request.assignee).to eq(project.creator)
        expect(merge_request.description).to eq("*Created by: bitbucket_user*\n\ndescription")
      end
    end

    context 'when none of the reviewers have an identity' do
      before do
        identity_2.destroy!
      end

      it 'does not set reviewer_ids' do
        importer.execute

        merge_request = project.merge_requests.first

        expect(merge_request.reviewer_ids).to be_empty
      end
    end

    context 'when closed by user cannot be found' do
      before do
        User.find(closed_by_user.id).destroy!
      end

      it 'sets the merged by user to the project creator' do
        importer.execute

        expect(project.merge_requests.first.metrics.merged_by_id).to eq(project.creator_id)
        expect(project.merge_requests.first.metrics.latest_closed_by_id).to be_nil
      end

      context 'when merge state is closed' do
        let(:hash) { super().merge(state: 'closed') }

        it 'sets the closed by user to the project creator' do
          importer.execute

          expect(project.merge_requests.first.metrics.latest_closed_by_id).to eq(project.creator_id)
          expect(project.merge_requests.first.metrics.merged_by_id).to be_nil
        end
      end
    end

    describe 'head_commit_sha for merge request diff' do
      let(:diff) { project.merge_requests.first.merge_request_diffs.first }
      let(:min_length) { Commit::MIN_SHA_LENGTH }

      context 'when the source commit hash from Bitbucket is found on the repo' do
        it 'is set to the source commit hash' do
          described_class.new(project, hash.merge(source_branch_sha: source_branch_sha)).execute

          expect(diff.head_commit_sha).to eq(source_branch_sha)
        end
      end

      context 'when the source commit hash is not found but the merge commit hash is found' do
        it 'is set to the merge commit hash' do
          attrs = { source_branch_sha: 'x' * min_length, merge_commit_sha: source_branch_sha }

          described_class.new(project, hash.merge(attrs)).execute

          expect(diff.head_commit_sha).to eq(source_branch_sha)
        end
      end

      context 'when both the source commit and merge commit hash are not found' do
        it 'is nil' do
          attrs = { source_branch_sha: 'x' * min_length, merge_commit_sha: 'y' * min_length }

          described_class.new(project, hash.merge(attrs)).execute

          expect(diff.head_commit_sha).to be_nil
        end
      end
    end

    context 'when an error is raised' do
      before do
        allow(Gitlab::Import::MergeRequestCreator).to receive(:new).and_raise(StandardError)
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        importer.execute
      end
    end

    it 'logs its progress' do
      allow(Gitlab::Import::MergeRequestCreator).to receive_message_chain(:new, :execute)

      expect(Gitlab::BitbucketImport::Logger)
        .to receive(:info).with(include(message: 'starting', iid: anything)).and_call_original
      expect(Gitlab::BitbucketImport::Logger)
        .to receive(:info).with(include(message: 'finished', iid: anything)).and_call_original

      importer.execute
    end

    it 'increments the merge requests counter' do
      expect_next_instance_of(Gitlab::Import::Metrics) do |metrics|
        expect(metrics).to receive_message_chain(:merge_requests_counter, :increment)
      end

      importer.execute
    end
  end
end
