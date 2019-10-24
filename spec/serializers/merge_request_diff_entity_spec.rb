# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestDiffEntity do
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }
  let(:merge_request_diff) { merge_request_diffs.first }

  let(:entity) do
    described_class.new(merge_request_diff, request: request, merge_request: merge_request, merge_request_diffs: merge_request_diffs)
  end

  subject { entity.as_json }

  context 'as json' do
    it 'exposes needed attributes' do
      expect(subject).to include(
        :version_index, :created_at, :commits_count,
        :latest, :short_commit_sha, :version_path,
        :compare_path
      )
    end
  end

  describe '#short_commit_sha' do
    it 'returns short sha' do
      expect(subject[:short_commit_sha]).to eq('b83d6e39')
    end

    it 'returns nil if head_commit_sha does not exist' do
      allow(merge_request_diff).to receive(:head_commit_sha).and_return(nil)

      expect(subject[:short_commit_sha]).to eq(nil)
    end
  end
end
