# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::PullRequestEntity, feature_category: :integrations do
  let_it_be(:project) { create_default(:project, :repository) }
  let_it_be(:merge_requests) { create_list(:merge_request, 2, :unique_branches) }
  let_it_be(:notes) { create_list(:note, 2, system: false, noteable: merge_requests.first) }
  let_it_be(:merge_request_reviewers) { create_pair(:merge_request_reviewer, merge_request: merge_requests[0]) }

  subject { described_class.represent(merge_requests).as_json }

  it 'exposes commentCount' do
    expect(subject.first[:commentCount]).to eq(2)
  end

  it 'exposes reviewers' do
    expect(subject.first[:reviewers].count).to eq(2)
  end

  context 'with user_notes_count option' do
    let(:user_notes_count) { merge_requests.to_h { |merge_request| [merge_request.id, 1] } }

    subject { described_class.represent(merge_requests, user_notes_count: user_notes_count).as_json }

    it 'avoids N+1 database queries' do
      control = ActiveRecord::QueryRecorder.new do
        described_class.represent(merge_requests, user_notes_count: user_notes_count)
      end

      merge_requests << create(:merge_request, :unique_branches)

      # In normal use of this entity, reviewer data is preloaded in JiraConnect::SyncService
      ActiveRecord::Associations::Preloader.new(
        records: merge_requests, associations: { merge_request_reviewers: :reviewer }
      ).call

      expect { subject }.not_to exceed_query_limit(control)
    end

    it 'uses counts from user_notes_count' do
      expect(subject.map { |entity| entity[:commentCount] }).to match_array([1, 1, 1])
    end

    context 'when count is missing for some MRs' do
      let(:user_notes_count) { [[merge_requests.last.id, 1]].to_h }

      it 'uses 0 as default when count for the MR is not available' do
        expect(subject.map { |entity| entity[:commentCount] }).to match_array([0, 0, 1])
      end
    end
  end
end
