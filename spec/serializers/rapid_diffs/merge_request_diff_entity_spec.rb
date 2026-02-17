# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::MergeRequestDiffEntity, feature_category: :code_review_workflow do
  let(:merge_request_diff) { build_stubbed(:merge_request_diff) }
  let(:merge_request) { merge_request_diff.merge_request }

  let(:entity) do
    described_class.new(
      merge_request_diff,
      merge_request_diffs: [],
      merge_request: merge_request
    )
  end

  subject(:serialized) { entity.as_json }

  context 'as json' do
    it 'exposes needed attributes' do
      expect(serialized).to include(:id, :head_commit_sha)
    end
  end
end
