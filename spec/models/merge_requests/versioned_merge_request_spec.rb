# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::VersionedMergeRequest, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { build_stubbed(:merge_request) }
  let(:merge_request_diff) { instance_double(MergeRequestDiff) }
  let(:diff_options) { { expanded: true } }
  let(:diffs_result) { instance_double(Gitlab::Diff::FileCollection::MergeRequestDiff) }

  subject(:versioned) { described_class.new(merge_request) }

  before do
    allow(merge_request).to receive_messages(
      compare: nil,
      merge_request_diff: merge_request_diff,
      diffable_merge_ref?: false
    )
  end

  describe '#class' do
    it 'returns the class of the wrapped merge request' do
      expect(versioned.class).to eq(MergeRequest)
    end
  end

  describe '#diffs', :aggregate_failures do
    context 'when compare is present' do
      let(:compare) { instance_double(Compare) }
      let(:compare_diffs) { instance_double(Gitlab::Diff::FileCollection::Compare) }

      before do
        allow(merge_request).to receive(:compare).and_return(compare)
        allow(compare).to receive(:diffs).and_return(compare_diffs)
      end

      it 'delegates to compare with expanded: true' do
        versioned.diffs(diff_options)

        expect(compare).to have_received(:diffs).with(diff_options.merge(expanded: true))
      end
    end

    context 'when show_context_commits_diff? is true' do
      let(:show_context_commits_diff?) { true }
      let(:diffs) { instance_double(Gitlab::Diff::FileCollection::Compare) }
      let(:context_commits_diff) { instance_double(ContextCommitsDiff) }

      before do
        allow(merge_request)
          .to receive_messages(
            show_context_commits_diff?: show_context_commits_diff?,
            context_commits_diff: context_commits_diff
          )

        allow(context_commits_diff).to receive(:diffs).and_return(diffs)
      end

      it 'delegates to context_commits_diff' do
        versioned.diffs(diff_options)

        expect(context_commits_diff).to have_received(:diffs).with(diff_options)
      end
    end

    context 'when compare is not present' do
      let(:diff_version) { instance_double(Gitlab::MergeRequests::DiffResolver) }
      let(:resolved_diff) { merge_request_diff }

      before do
        allow(resolved_diff).to receive(:diffs).and_return(diffs_result)
        allow(Gitlab::MergeRequests::DiffResolver).to receive(:new)
          .with(merge_request, {})
          .and_return(diff_version)
        allow(diff_version).to receive(:resolve).and_return(resolved_diff)
      end

      it 'resolves the diff version and returns its diffs' do
        expect(versioned.diffs(diff_options)).to eq(diffs_result)
        expect(resolved_diff).to have_received(:diffs).with(diff_options)
      end

      it 'strips version params from forwarded options' do
        versioned.diffs(expanded: true, diff_id: 42, start_sha: 'abc', commit_id: 'def')

        expect(resolved_diff).to have_received(:diffs).with(expanded: true)
      end

      it 'does not mutate the input diff_options hash' do
        original_options = { diff_id: 42, start_sha: 'abc123', expanded: true }
        options_copy = original_options.dup

        versioned.diffs(original_options)

        expect(original_options).to eq(options_copy)
      end

      context 'with version params in constructor' do
        subject(:versioned) do
          described_class.new(merge_request, version_params: { diff_id: 42, start_sha: 'abc123' })
        end

        before do
          allow(Gitlab::MergeRequests::DiffResolver).to receive(:new)
            .with(merge_request, { diff_id: 42, start_sha: 'abc123' })
            .and_return(diff_version)
        end

        it 'uses constructor version params for resolution' do
          versioned.diffs(expanded: true)

          expect(Gitlab::MergeRequests::DiffResolver).to have_received(:new)
            .with(merge_request, { diff_id: 42, start_sha: 'abc123' })
        end
      end
    end
  end

  describe '#diff_stats' do
    let(:diff_stats_result) { instance_double(Gitlab::Git::DiffStatsCollection) }

    context 'when compare is present' do
      let(:compare) { instance_double(Compare) }

      before do
        allow(merge_request).to receive_messages(compare: compare, diff_stats: diff_stats_result)
      end

      it 'delegates to the merge request' do
        expect(versioned.diff_stats).to eq(diff_stats_result)
      end
    end

    context 'when show_context_commits_diff? is true' do
      let(:show_context_commits_diff?) { true }
      let(:context_commits_diff) { instance_double(ContextCommitsDiff) }

      before do
        allow(merge_request)
          .to receive_messages(
            show_context_commits_diff?: show_context_commits_diff?,
            context_commits_diff: context_commits_diff
          )

        allow(context_commits_diff).to receive(:diff_stats).and_return(diff_stats_result)
      end

      it 'delegates to context_commits_diff' do
        expect(versioned.diff_stats).to eq(diff_stats_result)
      end
    end

    context 'when compare is not present' do
      let(:diff_version) { instance_double(Gitlab::MergeRequests::DiffResolver) }
      let(:resolved_diff) { merge_request_diff }

      before do
        allow(resolved_diff).to receive(:diff_stats).and_return(diff_stats_result)
        allow(Gitlab::MergeRequests::DiffResolver).to receive(:new)
          .with(merge_request, {})
          .and_return(diff_version)
        allow(diff_version).to receive(:resolve).and_return(resolved_diff)
      end

      it 'resolves the diff version and returns its diff_stats' do
        expect(versioned.diff_stats).to eq(diff_stats_result)
      end

      context 'with diff_id in constructor options' do
        subject(:versioned) { described_class.new(merge_request, version_params: { diff_id: 42 }) }

        let(:resolved_diff) { instance_double(MergeRequestDiff) }

        before do
          allow(resolved_diff).to receive(:diff_stats).and_return(diff_stats_result)
          allow(Gitlab::MergeRequests::DiffResolver).to receive(:new)
            .with(merge_request, { diff_id: 42 })
            .and_return(diff_version)
        end

        it 'uses the constructor diff_id to resolve the version' do
          expect(versioned.diff_stats).to eq(diff_stats_result)
          expect(Gitlab::MergeRequests::DiffResolver).to have_received(:new)
            .with(merge_request, { diff_id: 42 })
        end
      end

      context 'with start_sha and diff_id in constructor options' do
        subject(:versioned) do
          described_class.new(merge_request, version_params: { diff_id: 42, start_sha: 'abc123' })
        end

        before do
          allow(resolved_diff).to receive(:diff_stats).and_return(diff_stats_result)
          allow(Gitlab::MergeRequests::DiffResolver).to receive(:new)
            .with(merge_request, { diff_id: 42, start_sha: 'abc123' })
            .and_return(diff_version)
        end

        it 'passes both version params to DiffResolver' do
          versioned.diff_stats

          expect(Gitlab::MergeRequests::DiffResolver).to have_received(:new)
            .with(merge_request, { diff_id: 42, start_sha: 'abc123' })
        end
      end
    end
  end

  it 'delegates other methods to the merge request', :aggregate_failures do
    expect(versioned.id).to eq(merge_request.id)
    expect(versioned.project).to eq(merge_request.project)
  end
end
