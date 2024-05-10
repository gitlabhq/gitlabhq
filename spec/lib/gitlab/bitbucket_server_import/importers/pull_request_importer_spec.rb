# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestImporter, feature_category: :importers do
  include AfterNextHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:reviewer_1) { create(:user, username: 'john_smith', email: 'john@smith.com') }
  let_it_be(:reviewer_2) { create(:user, username: 'jane_doe', email: 'jane@doe.com') }

  let(:pull_request_data) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/pull_request.json')) }
  let(:pull_request) { BitbucketServer::Representation::PullRequest.new(pull_request_data) }

  subject(:importer) { described_class.new(project, pull_request.to_hash) }

  describe '#execute' do
    it 'imports the merge request correctly' do
      expect_next(Gitlab::Import::MergeRequestCreator, project).to receive(:execute).and_call_original
      expect_next(Gitlab::BitbucketServerImport::UserFinder, project).to receive(:author_id).and_call_original
      expect_next(Gitlab::Import::MentionsConverter, 'bitbucket_server',
        project).to receive(:convert).and_call_original

      expect { importer.execute }.to change { MergeRequest.count }.by(1)

      merge_request = project.merge_requests.find_by_iid(pull_request.iid)

      expect(merge_request).to have_attributes(
        iid: pull_request.iid,
        title: pull_request.title,
        source_branch: 'root/CODE_OF_CONDUCTmd-1530600625006',
        target_branch: 'master',
        reviewer_ids: match_array([reviewer_1.id, reviewer_2.id]),
        state: pull_request.state,
        author_id: project.creator_id,
        description: "*Created by: #{pull_request.author}*\n\n#{pull_request.description}"
      )
    end

    context 'when the `bitbucket_server_convert_mentions_to_users` flag is disabled' do
      before do
        stub_feature_flags(bitbucket_server_convert_mentions_to_users: false)
      end

      it 'does not convert mentions' do
        expect_next(Gitlab::Import::MentionsConverter, 'bitbucket_server', project).not_to receive(:convert)

        importer.execute
      end
    end

    context 'when the `bitbucket_server_user_mapping_by_username` flag is disabled' do
      before do
        stub_feature_flags(bitbucket_server_user_mapping_by_username: false)
      end

      it 'imports reviewers correctly' do
        importer.execute

        merge_request = project.merge_requests.find_by_iid(pull_request.iid)

        expect(merge_request.reviewer_ids).to match_array([reviewer_1.id, reviewer_2.id])
      end
    end

    describe 'merge request diff head_commit_sha' do
      before do
        allow(pull_request).to receive(:source_branch_sha).and_return(source_branch_sha)
      end

      context 'when a commit with the source_branch_sha exists' do
        let(:source_branch_sha) { project.repository.head_commit.sha }

        it 'is equal to the source_branch_sha' do
          importer.execute

          merge_request = project.merge_requests.find_by_iid(pull_request.iid)

          expect(merge_request.merge_request_diffs.first.head_commit_sha).to eq(source_branch_sha)
        end
      end

      context 'when a commit with the source_branch_sha does not exist' do
        let(:source_branch_sha) { 'x' * Commit::MIN_SHA_LENGTH }

        it 'is nil' do
          importer.execute

          merge_request = project.merge_requests.find_by_iid(pull_request.iid)

          expect(merge_request.merge_request_diffs.first.head_commit_sha).to be_nil
        end

        context 'when a commit containing the sha in the message exists' do
          let(:source_branch_sha) { project.repository.head_commit.sha }

          it 'is equal to the sha' do
            message = "
            Squashed commit of the following:

            commit #{source_branch_sha}
            Author: John Smith <john@smith.com>
            Date:   Mon Sep 18 15:58:38 2023 +0200

            My commit message
            "

            Files::CreateService.new(
              project,
              project.creator,
              start_branch: 'master',
              branch_name: 'master',
              commit_message: message,
              file_path: 'files/lfs/ruby.rb',
              file_content: 'testing'
            ).execute

            importer.execute

            merge_request = project.merge_requests.find_by_iid(pull_request.iid)

            expect(merge_request.merge_request_diffs.first.head_commit_sha).to eq(source_branch_sha)
          end
        end
      end
    end

    it 'logs its progress' do
      expect(Gitlab::BitbucketServerImport::Logger)
        .to receive(:info).with(include(message: 'starting', iid: pull_request.iid)).and_call_original
      expect(Gitlab::BitbucketServerImport::Logger)
        .to receive(:info).with(include(message: 'finished', iid: pull_request.iid)).and_call_original

      importer.execute
    end
  end
end
