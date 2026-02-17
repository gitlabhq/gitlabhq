# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::DiffVersion, feature_category: :code_review_workflow do
  let(:merge_request) { build_stubbed(:merge_request) }
  let(:params) { {} }
  let(:diff_version) { described_class.new(merge_request, params) }

  describe '#resolve' do
    let(:base_diff) { instance_double(MergeRequestDiff) }
    let(:head_diff) { instance_double(MergeRequestDiff) }
    let(:diffable_merge_ref?) { false }

    before do
      allow(merge_request)
        .to receive_messages(
          diffable_merge_ref?: diffable_merge_ref?,
          merge_request_diff: base_diff,
          merge_head_diff: head_diff
        )
    end

    it 'returns base diff' do
      expect(diff_version.resolve).to eq(base_diff)
    end

    context 'when HEAD diff is diffable' do
      let(:diffable_merge_ref?) { true }

      it 'returns HEAD diff' do
        expect(diff_version.resolve).to eq(head_diff)
      end
    end
  end
end
