# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::DiffResolver, feature_category: :code_review_workflow do
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

    # `MergeRequestDiff#set_as_latest_diff` is called in `after_commit` which
    # gets skipped in specs so we replicate it here. This is so we can set this
    # as the latest diff.
    merge_request.create_merge_request_diff.tap do |diff|
      merge_request.update_column(:latest_merge_request_diff_id, diff.id)
    end
  end

  let_it_be(:head_diff) { create(:merge_request_diff, :merge_head, merge_request: merge_request) }
  let(:params) { {} }
  let(:diff_resolver) { described_class.new(merge_request, params) }

  describe '#resolve' do
    let(:diffable_merge_ref?) { false }

    before do
      allow(merge_request)
        .to receive(:diffable_merge_ref?)
        .and_return(diffable_merge_ref?)
    end

    it 'returns base diff' do
      expect(diff_resolver.resolve).to eq(base_diff_2)
    end

    context 'when latest_merge_request_diff is not set' do
      before do
        allow(merge_request)
          .to receive(:latest_merge_request_diff)
          .and_return(nil)
      end

      it 'returns associated merge_request_diff' do
        expect(diff_resolver.resolve).to eq(merge_request.merge_request_diff)
      end
    end

    context 'when compare is present' do
      let(:compare) { instance_double(Compare) }

      before do
        merge_request.compare = compare
      end

      after do
        merge_request.compare = nil
      end

      it 'returns compare' do
        expect(diff_resolver.resolve).to eq(compare)
      end
    end

    context 'when diff_id param is set' do
      let(:params) { { diff_id: base_diff_1.id } }

      it 'returns the specific diff by ID' do
        expect(diff_resolver.resolve).to eq(base_diff_1)
      end

      context 'when diff_id does not match any diff' do
        let(:params) { { diff_id: base_diff_1.id + 999 } }

        it 'raises error' do
          expect { diff_resolver.resolve }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'when diff_id is the latest diff' do
        let(:params) { { diff_id: base_diff_2.id } }

        it 'returns the latest base diff' do
          expect(diff_resolver.resolve).to eq(base_diff_2)
        end

        context 'when HEAD diff is diffable' do
          let(:diffable_merge_ref?) { true }

          it 'returns HEAD diff' do
            expect(diff_resolver.resolve).to eq(head_diff)
          end

          context 'when start_sha is present' do
            let(:params) { { diff_id: base_diff_2.id, start_sha: base_diff_1.head_commit_sha } }

            it 'returns a comparison between versions instead of HEAD diff' do
              diff = diff_resolver.resolve

              expect(diff).to be_a(Compare)
              expect(diff.diffs.diff_files.map(&:file_path)).to eq(['new_file.txt'])
            end
          end
        end
      end

      context 'when diff_id is not the latest diff and HEAD diff is diffable' do
        let(:params) { { diff_id: base_diff_1.id } }
        let(:diffable_merge_ref?) { true }

        it 'returns the requested diff, not the HEAD diff' do
          expect(diff_resolver.resolve).to eq(base_diff_1)
        end
      end

      context 'when latest_merge_request_diff is nil and diff_id is present' do
        let(:params) { { diff_id: base_diff_2.id } }
        let(:diffable_merge_ref?) { true }

        before do
          allow(merge_request).to receive(:latest_merge_request_diff_id).and_return(nil)
        end

        it 'returns the requested diff instead of raising' do
          expect(diff_resolver.resolve).to eq(base_diff_2)
        end
      end

      context 'when start_sha param is set' do
        let(:params) { { diff_id: base_diff_2.id, start_sha: base_diff_1.head_commit_sha } }

        it 'returns a comparison between versions' do
          diff = diff_resolver.resolve

          expect(diff).to be_a(Compare)
          expect(diff.diffs.diff_files.map(&:file_path)).to eq(['new_file.txt'])
        end

        context 'when start_sha does not match any diff' do
          let(:params) { { diff_id: base_diff_2.id, start_sha: 'abc123' } }

          it 'returns matching diff' do
            expect(diff_resolver.resolve).to eq(base_diff_2)
          end
        end
      end
    end

    context 'when HEAD diff is diffable' do
      let(:diffable_merge_ref?) { true }

      it 'returns HEAD diff' do
        expect(diff_resolver.resolve).to eq(head_diff)
      end
    end

    context 'when commit_id param is set' do
      let(:params) { { commit_id: commit_sha } }
      let(:expected_commit) { merge_request.project.commit(commit_sha) }

      it 'returns matching commit' do
        expect(diff_resolver.resolve).to eq(expected_commit)
      end

      context 'when commit_id does not match a commit' do
        let(:params) { { commit_id: 'abc123' } }

        it 'returns latest diff' do
          expect(diff_resolver.resolve).to eq(base_diff_2)
        end
      end
    end
  end
end
