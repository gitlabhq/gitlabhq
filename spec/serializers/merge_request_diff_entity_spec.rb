require 'spec_helper'

describe MergeRequestDiffEntity do
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }

  let(:entity) do
    described_class.new(merge_request_diffs.first, request: request, merge_request: merge_request, merge_request_diffs: merge_request_diffs)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'exposes needed attributes' do
      expect(subject).to include(
        :version_index, :created_at, :commits_count,
        :latest, :short_commit_sha, :version_path,
        :compare_path
      )
    end
  end
end
