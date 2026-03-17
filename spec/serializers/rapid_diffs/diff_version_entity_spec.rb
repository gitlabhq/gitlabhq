# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffVersionEntity, feature_category: :code_review_workflow do
  include Gitlab::Routing.url_helpers
  include MergeRequestsHelper

  let_it_be(:merge_request) { build_stubbed(:merge_request, :skip_diff_creation) }
  let_it_be(:diff_1) { build_stubbed(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:diff_2) { build_stubbed(:merge_request_diff, merge_request: merge_request, head_commit_sha: 'abc123def') }

  let(:merge_request_diffs) { [diff_2, diff_1] }
  let(:diff_id) { nil }
  let(:start_sha) { nil }

  let(:options) do
    {
      merge_request: merge_request,
      merge_request_diffs: merge_request_diffs,
      diff_id: diff_id,
      start_sha: start_sha
    }
  end

  let(:merge_request_diff) { diff_2 }
  let(:entity) { described_class.new(merge_request_diff, options) }

  subject(:serialized) { entity.as_json }

  describe 'serialization' do
    it 'inherits attributes from DiffVersionEntity' do
      expect(serialized).to include(
        :id,
        :version_index,
        :head,
        :latest,
        :short_commit_sha,
        :commits_count,
        :created_at
      )
    end
  end

  describe 'version_index' do
    it 'returns the calculated version index' do
      expect(serialized[:version_index]).to eq(2)
    end

    context 'when diff is not included in merge_request_diffs list' do
      let(:merge_request_diff) { build_stubbed(:merge_request_diff, merge_request: merge_request) }

      it 'returns nil' do
        expect(serialized[:version_index]).to be_nil
      end
    end

    context 'when there is only 1 merge request diff' do
      let(:merge_request_diffs) { [diff_2] }

      it 'returns nil' do
        expect(serialized[:version_index]).to be_nil
      end
    end
  end

  describe '#short_commit_sha' do
    it 'returns short sha' do
      expect(serialized[:short_commit_sha]).to eq('abc123de')
    end

    it 'returns nil if head_commit_sha does not exist' do
      allow(merge_request_diff).to receive(:head_commit_sha).and_return(nil)

      expect(serialized[:short_commit_sha]).to be_nil
    end
  end
end
