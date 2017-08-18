require 'spec_helper'

describe Gitlab::BackgroundMigration::DeserializeMergeRequestDiffsAndCommits do
  describe '#perform' do
    set(:merge_request) { create(:merge_request) }
    set(:merge_request_diff) { merge_request.merge_request_diff }
    let(:updated_merge_request_diff) { MergeRequestDiff.find(merge_request_diff.id) }

    def diffs_to_hashes(diffs)
      diffs.as_json(only: Gitlab::Git::Diff::SERIALIZE_KEYS).map(&:with_indifferent_access)
    end

    def quote_yaml(value)
      MergeRequestDiff.connection.quote(YAML.dump(value))
    end

    def convert_to_yaml(merge_request_diff_id, commits, diffs)
      MergeRequestDiff.where(id: merge_request_diff_id).update_all(
        "st_commits = #{quote_yaml(commits)}, st_diffs = #{quote_yaml(diffs)}"
      )
    end

    shared_examples 'updated MR diff' do
      before do
        convert_to_yaml(merge_request_diff.id, commits, diffs)

        MergeRequestDiffCommit.delete_all
        MergeRequestDiffFile.delete_all

        subject.perform(merge_request_diff.id, merge_request_diff.id)
      end

      it 'creates correct entries in the merge_request_diff_commits table' do
        expect(updated_merge_request_diff.merge_request_diff_commits.count).to eq(commits.count)
        expect(updated_merge_request_diff.commits.map(&:to_hash)).to eq(commits)
      end

      it 'creates correct entries in the merge_request_diff_files table' do
        expect(updated_merge_request_diff.merge_request_diff_files.count).to eq(expected_diffs.count)
        expect(diffs_to_hashes(updated_merge_request_diff.raw_diffs)).to eq(expected_diffs)
      end

      it 'sets the st_commits and st_diffs columns to nil' do
        expect(updated_merge_request_diff.st_commits_before_type_cast).to be_nil
        expect(updated_merge_request_diff.st_diffs_before_type_cast).to be_nil
      end
    end

    context 'when the diff IDs passed do not exist' do
      it 'does not raise' do
        expect { subject.perform(0, 0) }.not_to raise_exception
      end
    end

    context 'when the merge request diff has no serialised commits or diffs' do
      before do
        merge_request_diff.update(st_commits: nil, st_diffs: nil)
      end

      it 'does not raise' do
        expect { subject.perform(merge_request_diff.id, merge_request_diff.id) }
          .not_to raise_exception
      end
    end

    context 'processing multiple merge request diffs' do
      let(:start_id) { described_class::MergeRequestDiff.minimum(:id) }
      let(:stop_id) { described_class::MergeRequestDiff.maximum(:id) }

      before do
        merge_request.reload_diff(true)

        convert_to_yaml(start_id, merge_request_diff.commits, merge_request_diff.diffs)
        convert_to_yaml(stop_id, updated_merge_request_diff.commits, updated_merge_request_diff.diffs)

        MergeRequestDiffCommit.delete_all
        MergeRequestDiffFile.delete_all
      end

      context 'when BUFFER_ROWS is exceeded' do
        before do
          stub_const("#{described_class}::BUFFER_ROWS", 1)
        end

        it 'updates and continues' do
          expect(described_class::MergeRequestDiff).to receive(:transaction).twice

          subject.perform(start_id, stop_id)
        end
      end

      context 'when BUFFER_ROWS is not exceeded' do
        it 'only updates once' do
          expect(described_class::MergeRequestDiff).to receive(:transaction).once

          subject.perform(start_id, stop_id)
        end
      end
    end

    context 'when the merge request diff update fails' do
      before do
        allow(described_class::MergeRequestDiff)
          .to receive(:update_all).and_raise(ActiveRecord::Rollback)
      end

      it 'does not add any diff commits' do
        expect { subject.perform(merge_request_diff.id, merge_request_diff.id) }
          .not_to change { MergeRequestDiffCommit.count }
      end

      it 'does not add any diff files' do
        expect { subject.perform(merge_request_diff.id, merge_request_diff.id) }
          .not_to change { MergeRequestDiffFile.count }
      end
    end

    context 'when the merge request diff has valid commits and diffs' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }
      let(:expected_diffs) { diffs }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs do not have too_large set' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }

      let(:diffs) do
        expected_diffs.map { |diff| diff.except(:too_large) }
      end

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs do not have a_mode and b_mode set' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }

      let(:diffs) do
        expected_diffs.map { |diff| diff.except(:a_mode, :b_mode) }
      end

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs have binary content' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_diffs) { diffs }

      # The start of a PDF created by Illustrator
      let(:binary_string) do
        "\x25\x50\x44\x46\x2d\x31\x2e\x35\x0d\x25\xe2\xe3\xcf\xd3\x0d\x0a".force_encoding(Encoding::BINARY)
      end

      let(:diffs) do
        [
          {
            'diff' => binary_string,
            'new_path' => 'path',
            'old_path' => 'path',
            'a_mode' => '100644',
            'b_mode' => '100644',
            'new_file' => false,
            'renamed_file' => false,
            'deleted_file' => false,
            'too_large' => false
          }
        ]
      end

      include_examples 'updated MR diff'
    end

    context 'when the merge request diff has commits, but no diffs' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:diffs) { [] }
      let(:expected_diffs) { diffs }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs have invalid content' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:diffs) { ['--broken-diff'] }
      let(:expected_diffs) { [] }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs are Rugged::Patch instances' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:first_commit) { merge_request.project.repository.commit(merge_request_diff.head_commit_sha) }
      let(:diffs) { first_commit.diff_from_parent.patches }
      let(:expected_diffs) { [] }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs are Rugged::Diff::Delta instances' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:first_commit) { merge_request.project.repository.commit(merge_request_diff.head_commit_sha) }
      let(:diffs) { first_commit.diff_from_parent.deltas }
      let(:expected_diffs) { [] }

      include_examples 'updated MR diff'
    end
  end
end
