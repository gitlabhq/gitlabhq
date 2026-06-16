# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::Base, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request) }
  let(:diffable) { merge_request.merge_request_diff }
  let(:diff_options) { {} }

  describe '#overflow?' do
    subject(:overflown) { described_class.new(diffable, project: merge_request.project, diff_options: diff_options).overflow? }

    context 'when it is not overflown' do
      it 'returns false' do
        expect(overflown).to eq(false)
      end
    end

    context 'when it is overflown' do
      let(:diff_options) { { max_files: 1 } }

      it 'returns true' do
        expect(overflown).to eq(true)
      end
    end
  end

  describe '#raw_diff_files' do
    let(:max_blob_size) { 10 }

    it 'returns diffs that contain a maximum of max_blob_size of data' do
      allow(described_class).to receive(:max_blob_size).and_return(max_blob_size)

      expect(described_class.new(diffable, project: merge_request.project).raw_diff_files.all? { |file| file.max_blob_size == max_blob_size }).to be_truthy
    end
  end

  describe 'rename diff stats' do
    let(:project) { merge_request.project }
    let(:diff_refs) do
      instance_double(Gitlab::Diff::DiffRefs, base_sha: 'base', head_sha: 'head')
    end

    # Gitaly reports inflated stats because it treats the rename as a full rewrite:
    # 57 additions (entire new file) and 13 deletions (entire old file).
    # These should be ignored in favour of parsing the actual diff lines.
    let(:new_path_stats) { Gitaly::DiffStats.new(path: 'new.py', additions: 57, deletions: 0) }
    let(:old_path_stats) { Gitaly::DiffStats.new(path: 'old.py', additions: 0, deletions: 13) }
    let(:diff_stats_collection) { Gitlab::Git::DiffStatsCollection.new([new_path_stats, old_path_stats]) }
    let(:renamed_diff) do
      {
        old_path: 'old.py',
        new_path: 'new.py',
        renamed_file: true,
        new_file: false,
        deleted_file: false,
        diff: <<~DIFF
          @@ -1,4 +1,5 @@
          def hello
          -    print("world")
          +    print("world!")
          +    print("done")
          end
        DIFF
      }
    end

    let(:diff_collection) { Gitlab::Git::DiffCollection.new([renamed_diff]) }
    let(:diffable) do
      instance_double(
        MergeRequestDiff,
        raw_diffs: diff_collection,
        diff_stats: diff_stats_collection
      )
    end

    it 'ignores Gitaly stats and counts actual diff lines for renamed files' do
      diff_file = described_class.new(diffable, project: project, diff_refs: diff_refs).diff_files.first

      expect(diff_file.renamed_file?).to be(true)
      # Gitaly stats report 57 additions and 13 deletions (full-file rewrite),
      # but the actual diff has only 2 added lines and 1 removed line.
      expect(diff_file.added_lines).to eq(2)
      expect(diff_file.removed_lines).to eq(1)
    end
  end
end
