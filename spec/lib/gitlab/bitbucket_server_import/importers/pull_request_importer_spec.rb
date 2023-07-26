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

    it 'logs its progress' do
      expect(Gitlab::BitbucketServerImport::Logger)
        .to receive(:info).with(include(message: 'starting', iid: pull_request.iid)).and_call_original
      expect(Gitlab::BitbucketServerImport::Logger)
        .to receive(:info).with(include(message: 'finished', iid: pull_request.iid)).and_call_original

      importer.execute
    end
  end
end
