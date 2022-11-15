# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter, :clean_gitlab_redis_cache do
  subject(:importer) { described_class.new(review_request, project, client) }

  let(:project) { instance_double('Project') }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:merge_request) { create(:merge_request) }
  let(:reviewer) { create(:user, username: 'alice') }
  let(:review_request) do
    Gitlab::GithubImport::Representation::PullRequests::ReviewRequests.from_json_hash(
      merge_request_id: merge_request.id,
      users: [
        { 'id' => 1, 'login' => reviewer.username },
        { 'id' => 2, 'login' => 'foo' }
      ]
    )
  end

  before do
    allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
      allow(finder).to receive(:find).with(1, reviewer.username).and_return(reviewer.id)
      allow(finder).to receive(:find).with(2, 'foo').and_return(nil)
    end
  end

  it 'imports merge request reviewers that were found' do
    importer.execute

    expect(merge_request.reviewers.size).to eq 1
    expect(merge_request.reviewers[0].id).to eq reviewer.id
  end
end
