# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::MergeRequestBasic do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:labels) { create_list(:label, 3) }
  let_it_be(:merge_requests) { create_list(:labeled_merge_request, 10, :unique_branches, labels: labels) }

  let_it_be(:entity) { described_class.new(merge_request) }

  # This mimics the behavior of the `Grape::Entity` serializer
  def present(obj)
    described_class.new(obj).presented
  end

  subject { entity.as_json }

  it 'includes basic fields' do
    is_expected.to include(
      draft: merge_request.draft?,
      work_in_progress: merge_request.draft?
    )
  end

  context "with :with_api_entity_associations scope" do
    let(:scope) { MergeRequest.with_api_entity_associations }

    it "avoids N+1 queries" do
      query = scope.find(merge_request.id)

      control = ActiveRecord::QueryRecorder.new do
        present(query).to_json
      end

      # stub the `head_commit_sha` as it will trigger a
      # backward compatibility query that is out-of-scope
      # for this test whenever it is `nil`
      allow_any_instance_of(MergeRequestDiff).to receive(:head_commit_sha).and_return(Gitlab::Git::BLANK_SHA)

      query = scope.all
      batch = ActiveRecord::QueryRecorder.new do
        entities = query.map(&method(:present))

        entities.to_json
      end

      # The current threshold is 3 query per entity maximum.
      expect(batch.count).to be_within(3 * query.count).of(control.count)
    end
  end

  context 'reviewers' do
    before do
      merge_request.reviewers = [user]
    end

    it 'includes assigned reviewers' do
      result = Gitlab::Json.parse(present(merge_request).to_json)

      expect(result['reviewers'][0]['username']).to eq user.username
    end
  end
end
