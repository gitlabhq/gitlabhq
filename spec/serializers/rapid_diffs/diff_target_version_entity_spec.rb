# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiffTargetVersionEntity, feature_category: :code_review_workflow do
  include Gitlab::Routing.url_helpers
  include MergeRequestsHelper

  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Needs persisted objects
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:merge_request) do
    create(
      :merge_request,
      :skip_diff_creation,
      source_project: project,
      target_project: project
    )
  end

  let_it_be(:diff_1) { create(:merge_request_diff, merge_request: merge_request) }
  let_it_be(:diff_2) { create(:merge_request_diff, merge_request: merge_request) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:merge_request_diffs) { [diff_2, diff_1] }
  let(:diff_id) { nil }
  let(:start_sha) { nil }

  let(:options) do
    {
      merge_request: merge_request.reload,
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
    context 'when diff is latest' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: true,
          merge_head?: false
        )
      end

      it 'returns nil' do
        expect(serialized[:version_index]).to be_nil
      end
    end

    context 'when diff is merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: true
        )
      end

      it 'returns nil' do
        expect(serialized[:version_index]).to be_nil
      end
    end

    context 'when diff is neither latest nor merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: false
        )
      end

      it 'returns the calculated version index' do
        expect(serialized[:version_index]).to eq(2)
      end
    end
  end

  describe 'selected' do
    context 'when diff is latest' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: true,
          merge_head?: false
        )
      end

      it 'returns true' do
        expect(serialized[:selected]).to be(true)
      end
    end

    context 'when diff is merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: true
        )
      end

      it 'returns true' do
        expect(serialized[:selected]).to be(true)
      end
    end

    context 'when diff is neither latest nor merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: false
        )
      end

      it 'returns false' do
        expect(serialized[:selected]).to be(false)
      end
    end

    context 'when start_sha is set' do
      let(:start_sha) { merge_request_diff.head_commit_sha }

      it 'returns true when head_commit_sha matches start_sha' do
        expect(serialized[:selected]).to be(true)
      end

      context 'when head_commit_sha does not match start_sha' do
        let(:start_sha) { 'different_sha' }

        it 'returns false' do
          expect(serialized[:selected]).to be(false)
        end
      end
    end
  end

  describe 'href' do
    context 'when diff is latest' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: true,
          merge_head?: false
        )
      end

      it 'returns diffs_project_merge_request_path without start_sha' do
        expected_path = diffs_project_merge_request_path(
          project,
          merge_request,
          rapid_diffs: true
        )

        expect(serialized[:href]).to eq(expected_path)
      end
    end

    context 'when diff is merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: true
        )
      end

      it 'returns diffs_project_merge_request_path without start_sha' do
        expected_path = diffs_project_merge_request_path(
          project,
          merge_request,
          rapid_diffs: true
        )

        expect(serialized[:href]).to eq(expected_path)
      end
    end

    context 'when diff is neither latest nor merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: false
        )
      end

      it 'returns merge_request_version_path with head_commit_sha as start_sha' do
        expected_path = merge_request_version_path(
          project,
          merge_request,
          merge_request.latest_merge_request_diff,
          rapid_diffs: true,
          start_sha: merge_request_diff.head_commit_sha
        )

        expect(serialized[:href]).to eq(expected_path)
      end

      context 'when diff_id is set' do
        let(:diff_id) { diff_1.id }

        before do
          allow_next_instance_of(
            ::Gitlab::MergeRequests::DiffVersion,
            merge_request,
            diff_id: diff_id
          ) do |resolver|
            allow(resolver).to receive(:resolve).and_return(diff_1)
          end
        end

        it 'uses matching merge request diff instead of latest diff' do
          expected_path = merge_request_version_path(
            project,
            merge_request,
            diff_1,
            rapid_diffs: true,
            start_sha: merge_request_diff.head_commit_sha
          )

          expect(serialized[:href]).to eq(expected_path)
        end
      end
    end
  end

  describe 'branch' do
    context 'when diff is latest' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: true,
          merge_head?: false
        )
      end

      it 'exposes the target branch' do
        expect(serialized[:branch]).to eq(merge_request.target_branch)
      end
    end

    context 'when diff is merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: true
        )
      end

      it 'exposes the target branch' do
        expect(serialized[:branch]).to eq(merge_request.target_branch)
      end
    end

    context 'when diff is neither latest nor merge_head' do
      before do
        allow(merge_request_diff).to receive_messages(
          latest?: false,
          merge_head?: false
        )
      end

      it 'does not expose branch' do
        expect(serialized).not_to have_key(:branch)
      end
    end
  end
end
