# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestImporter, feature_category: :importers do
  include AfterNextHelpers
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  # Identifiers taken from importers/bitbucket_server/pull_request.json
  let_it_be(:author_source_user) { generate_source_user(project, 'username') }
  let_it_be(:reviewer_1_source_user) { generate_source_user(project, 'john_smith') }
  let_it_be(:reviewer_2_source_user) { generate_source_user(project, 'jane_doe') }

  let(:pull_request_data) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/pull_request.json')) }
  let(:pull_request) { BitbucketServer::Representation::PullRequest.new(pull_request_data) }

  subject(:importer) { described_class.new(project, pull_request.to_hash) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'imports the merge request correctly' do
      expect_next(Gitlab::Import::MergeRequestCreator, project).to receive(:execute).and_call_original
      expect_next(Gitlab::BitbucketServerImport::UserFinder, project).to receive(:author_id).and_call_original

      expect { importer.execute }.to change { MergeRequest.count }.by(1)

      merge_request = project.merge_requests.find_by_iid(pull_request.iid)

      expect(merge_request).to have_attributes(
        iid: pull_request.iid,
        title: pull_request.title,
        source_branch: 'root/CODE_OF_CONDUCTmd-1530600625006',
        target_branch: 'master',
        reviewer_ids: an_array_matching([reviewer_1_source_user.mapped_user_id, reviewer_2_source_user.mapped_user_id]),
        state: pull_request.state,
        author_id: author_source_user.mapped_user_id,
        description: pull_request.description,
        imported_from: 'bitbucket_server'
      )
    end

    it 'pushes placeholder references', :aggregate_failures do
      importer.execute

      cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
      expect(cached_references).to contain_exactly(
        ['MergeRequestReviewer', instance_of(Integer), 'user_id', reviewer_1_source_user.id],
        ['MergeRequestReviewer', instance_of(Integer), 'user_id', reviewer_2_source_user.id],
        ['MergeRequest', instance_of(Integer), 'author_id', author_source_user.id]
      )
    end

    describe 'when handling @ username mentions' do
      let(:original_body) { "I said to @sam_allen.greg the code should follow @bob's advice. @.ali-ce/group#9?" }
      let(:expected_body) do
        "I said to `@sam_allen.greg` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?"
      end

      let(:pull_request_data) do
        Gitlab::Json.parse(fixture_file('importers/bitbucket_server/pull_request.json'))
        .merge({ "description" => original_body })
      end

      it 'inserts backticks around mentions' do
        importer.execute

        merge_request = project.merge_requests.find_by_iid(pull_request.iid)

        expect(merge_request.description).to eq(expected_body)
      end
    end

    describe 'refs/merge-requests/:iid/head creation' do
      before do
        project.repository.create_branch(pull_request.source_branch_name, 'master')
      end

      after do
        project.repository.delete_branch(pull_request.source_branch_name)
      end

      it 'creates head refs for imported merge requests' do
        importer.execute

        expect(
          project.repository.commit("refs/#{Repository::REF_MERGE_REQUEST}/#{pull_request.iid}/head")
        ).to be_present
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

    context 'when user contribution mapping is disabled' do
      let_it_be(:reviewer_1) { create(:user, username: 'john_smith', email: 'john@smith.com') }
      let_it_be(:reviewer_2) { create(:user, username: 'jane_doe', email: 'jane@doe.com') }

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'annotates the description with the source username when no matching user is found' do
        allow_next_instance_of(Gitlab::BitbucketServerImport::UserFinder) do |finder|
          allow(finder).to receive(:uid).and_return(nil)
        end

        importer.execute

        merge_request = project.merge_requests.find_by_iid(pull_request.iid)

        expect(merge_request).to have_attributes(
          description: "*Created by: #{pull_request.author}*\n\n#{pull_request.description}"
        )
      end

      context 'when alternate UCM flags are disabled' do
        before do
          stub_feature_flags(
            bitbucket_server_user_mapping: false
          )
        end

        it 'assigns the MR author' do
          importer.execute

          merge_request = project.merge_requests.find_by_iid(pull_request.iid)

          expect(merge_request.author_id).to eq(project.creator_id)
        end

        it 'imports reviewers correctly' do
          importer.execute

          merge_request = project.merge_requests.find_by_iid(pull_request.iid)

          expect(merge_request.reviewer_ids).to match_array([reviewer_1.id, reviewer_2.id])
        end
      end

      it 'does not push placeholder references' do
        importer.execute

        cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
        expect(cached_references).to be_empty
      end
    end
  end
end
