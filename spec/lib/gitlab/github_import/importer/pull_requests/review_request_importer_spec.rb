# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be(:project) { create(:project, :with_import_url, :import_user_mapping_enabled, :in_group) }
  let_it_be(:reviewer) { create(:user, username: 'alice') }
  let_it_be(:source_user) do
    create(
      :import_source_user,
      source_user_identifier: 1,
      source_hostname: project.import_url,
      import_type: Import::SOURCE_GITHUB,
      namespace: project.root_ancestor
    )
  end

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:merge_request) { create(:merge_request) }
  let(:review_request) do
    Gitlab::GithubImport::Representation::PullRequests::ReviewRequests.from_json_hash(
      merge_request_id: merge_request.id,
      users: [
        { 'id' => 1, 'login' => reviewer.username },
        { 'id' => 2, 'login' => 'foo' }
      ]
    )
  end

  let(:user_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  subject(:importer) { described_class.new(review_request, project, client) }

  before do
    allow(client).to receive(:user).and_return({ name: 'Github user name' })
  end

  it 'imports unique merge request reviewers as placeholders', :aggregate_failures do
    expect { 2.times { importer.execute } }.not_to raise_error

    reviewers = merge_request.reviewers

    expect(reviewers.size).to eq(2)
    expect(reviewers).to all(be_placeholder)
    expect(reviewers).to include(source_user.mapped_user)
  end

  it 'pushes placeholder references for unique merge request reviewers' do
    expect { 2.times { importer.execute } }.not_to raise_error

    # The existing placeholder will always have a lower id than the one created during import
    # so we can assume the first reviewer is for source_user when sorted by user_id
    created_reviewers = merge_request.merge_request_reviewers.sort_by(&:user_id)
    new_source_user_id = Import::SourceUser.last.id

    expect(user_references).to match_array([
      ['MergeRequestReviewer', created_reviewers.first.id, 'user_id', source_user.id],
      ['MergeRequestReviewer', created_reviewers.second.id, 'user_id', new_source_user_id]
    ])
  end

  context 'when user contribution mapping is disabled' do
    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(1, reviewer.username).and_return(reviewer.id)
        allow(finder).to receive(:find).with(2, 'foo').and_return(nil)
      end
    end

    it 'imports unique merge request reviewers that were found' do
      expect { 2.times { importer.execute } }.not_to raise_error

      expect(merge_request.reviewers.size).to eq(1)
      expect(merge_request.reviewers.first.id).to eq reviewer.id
    end

    it 'does not push any placeholder references' do
      expect(user_references).to be_empty
    end
  end
end
