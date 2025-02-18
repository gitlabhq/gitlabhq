# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffEntity, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }

  let(:request) { EntityRequest.new(project: project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }
  let(:merge_request_diff) { merge_request_diffs.first }

  let(:entity) { initialize_entity(merge_request, merge_request_diff) }

  def initialize_entity(merge_request, merge_request_diff)
    described_class.new(
      merge_request_diff,
      request: request,
      merge_request: merge_request,
      merge_request_diff: merge_request_diff,
      merge_request_diffs: merge_request_diffs
    )
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

  describe '#version_index' do
    shared_examples 'version_index is nil' do
      it 'returns nil' do
        expect(subject[:version_index]).to be_nil
      end
    end

    context 'when diff is not present' do
      let(:entity) do
        described_class.new(
          merge_request_diff,
          request: request,
          merge_request: merge_request,
          merge_request_diffs: merge_request_diffs
        )
      end

      it_behaves_like 'version_index is nil'
    end

    context 'when diff is not included in @merge_request_diffs' do
      let(:merge_request_diff) { create(:merge_request_diff) }
      let(:merge_request_diff_2) { create(:merge_request_diff) }

      before do
        merge_request_diffs << merge_request_diff_2
      end

      it_behaves_like 'version_index is nil'
    end

    context 'when @merge_request_diffs.size <= 1' do
      before do
        expect(merge_request_diffs.size).to eq(1)
      end

      it_behaves_like 'version_index is nil'
    end

    context 'when @merge_request_diffs.size > 1' do
      let(:merge_request) { create(:merge_request_with_multiple_diffs) }

      it 'returns difference between size and diff index',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/445703' do
        expect(merge_request_diffs.size).to eq(2)

        # diff index: 0
        subject = initialize_entity(merge_request, merge_request_diffs.first)
        expect(subject.as_json[:version_index]).to eq(2)

        # diff index: 1
        subject = initialize_entity(merge_request, merge_request_diffs.last)
        expect(subject.as_json[:version_index]).to eq(1)
      end
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

  describe '#head_version_path' do
    before do
      allow(merge_request).to receive(:diffable_merge_ref?)
        .and_return(diffable_merge_ref)
    end

    context 'merge request can be merged' do
      let(:diffable_merge_ref) { true }

      it 'returns diff path with diff_head param set' do
        expect(subject[:head_version_path]).to eq(
          "/#{project.full_path}/-/merge_requests/#{merge_request.iid}/diffs?diff_head=true"
        )
      end
    end

    context 'merge request cannot be merged' do
      let(:diffable_merge_ref) { false }

      it 'returns diff path with diff_head param set' do
        expect(subject[:head_version_path]).to be_nil
      end
    end
  end
end
