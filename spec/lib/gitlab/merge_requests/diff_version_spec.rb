# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::DiffVersion, feature_category: :code_review_workflow do
  include RepoHelpers

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:base_diff_1) { merge_request.merge_request_diff }

  let_it_be(:commit_sha) do
    create_file_in_repo(
      merge_request.project,
      'master',
      'master',
      'new_file.txt',
      'new content'
    )[:result]
  end

  let_it_be(:base_diff_2) do
    merge_request.clear_memoized_shas
    merge_request.create_merge_request_diff
  end

  let_it_be(:head_diff) { create(:merge_request_diff, :merge_head, merge_request: merge_request) }
  let(:params) { {} }
  let(:diff_version) { described_class.new(merge_request.reload, params) }

  describe '#resolve' do
    let(:diffable_merge_ref?) { false }

    before do
      allow(merge_request)
        .to receive(:diffable_merge_ref?)
        .and_return(diffable_merge_ref?)
    end

    it 'returns base diff' do
      expect(diff_version.resolve).to eq(base_diff_2)
    end

    context 'when diff_id param is set' do
      let(:params) { { diff_id: base_diff_1.id } }

      it 'returns the specific diff by ID' do
        expect(diff_version.resolve).to eq(base_diff_1)
      end

      context 'when diff_id does not match any diff' do
        let(:params) { { diff_id: base_diff_1.id + 999 } }

        it 'raises error' do
          expect { diff_version.resolve }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when start_sha param is set' do
        let(:params) { { diff_id: base_diff_2.id, start_sha: base_diff_1.head_commit_sha } }

        it 'returns a comparison between versions' do
          diff = diff_version.resolve

          expect(diff).to be_a(Compare)
          expect(diff.diffs.diff_files.map(&:file_path)).to eq(['new_file.txt'])
        end

        context 'when start_sha does not match any diff' do
          let(:params) { { diff_id: base_diff_2.id, start_sha: 'abc123' } }

          it 'returns matching diff' do
            expect(diff_version.resolve).to eq(base_diff_2)
          end
        end
      end
    end

    context 'when HEAD diff is diffable' do
      let(:diffable_merge_ref?) { true }

      it 'returns HEAD diff' do
        expect(diff_version.resolve).to eq(head_diff)
      end
    end

    context 'when commit_id param is set' do
      let(:params) { { commit_id: commit_sha } }
      let(:expected_commit) { merge_request.project.commit(commit_sha) }

      it 'returns matching commit' do
        expect(diff_version.resolve).to eq(expected_commit)
      end

      context 'when commit_id does not match a commit' do
        let(:params) { { commit_id: 'abc123' } }

        it 'returns latest diff' do
          expect(diff_version.resolve).to eq(base_diff_2)
        end
      end
    end
  end
end
