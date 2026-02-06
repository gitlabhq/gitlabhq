# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffEntity, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }

  let(:request) { EntityRequest.new(project: project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:merge_request_diffs) { merge_request.merge_request_diffs }
  let(:merge_request_diff) { merge_request_diffs.first }
  let(:full_path) { project.full_path }
  let(:iid) { merge_request.iid }
  let(:diff_id) { merge_request_diff.id }
  let(:start_sha) { merge_request_diff.head_commit_sha }
  let(:path_extra_options) { nil }
  let(:options) { {} }

  let(:entity) { initialize_entity(merge_request, merge_request_diff) }

  def initialize_entity(merge_request, merge_request_diff)
    described_class.new(
      merge_request_diff,
      request: request,
      merge_request: merge_request,
      merge_request_diff: merge_request_diff,
      merge_request_diffs: merge_request_diffs,
      path_extra_options: path_extra_options,
      **options
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
        quarantine: 'https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues/5967' do
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
          "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_head=true"
        )
      end

      context 'when path extra options are set' do
        let(:path_extra_options) { { rapid_diffs: true } }

        it 'returns diff path with extra options' do
          expect(subject[:head_version_path]).to eq(
            "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_head=true&rapid_diffs=true"
          )
        end
      end
    end

    context 'merge request cannot be merged' do
      let(:diffable_merge_ref) { false }

      it 'returns diff path with diff_head param set' do
        expect(subject[:head_version_path]).to be_nil
      end
    end
  end

  describe '#base_version_path' do
    it 'returns base version diff path' do
      expect(subject[:base_version_path]).to eq(
        "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}"
      )
    end

    context 'when path extra options are set' do
      let(:path_extra_options) { { rapid_diffs: true } }

      it 'returns diff path with extra options' do
        expect(subject[:base_version_path]).to eq(
          "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}&rapid_diffs=true"
        )
      end
    end
  end

  describe '#version_path' do
    it 'returns version diff path' do
      expect(subject[:version_path]).to eq(
        "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}"
      )
    end

    context 'when start_sha option is set' do
      let(:options) { { start_sha: 'abc123' } }

      it 'returns version diff path with start_sha' do
        expect(subject[:version_path]).to eq(
          "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}&start_sha=abc123"
        )
      end
    end

    context 'when path extra options are set' do
      let(:path_extra_options) { { rapid_diffs: true } }

      it 'returns diff path with extra options' do
        expect(subject[:version_path]).to eq(
          "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}&rapid_diffs=true"
        )
      end
    end
  end

  describe '#compare_path' do
    it 'returns version diff path' do
      expect(subject[:compare_path]).to eq(
        "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}&start_sha=#{start_sha}"
      )
    end

    context 'when path extra options are set' do
      let(:path_extra_options) { { rapid_diffs: true } }

      it 'returns diff path with extra options' do
        expect(subject[:compare_path]).to eq(
          "/#{full_path}/-/merge_requests/#{iid}/diffs?diff_id=#{diff_id}&rapid_diffs=true&start_sha=#{start_sha}"
        )
      end
    end
  end
end
