require 'spec_helper'

describe Gitlab::BackgroundMigration::DeserializeMergeRequestDiffsAndCommits, :migration, schema: 20171114162227 do
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:merge_requests) { table(:merge_requests) }

  describe '#perform' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { merge_requests.create!(iid: 1, target_project_id: project.id, source_project_id: project.id, target_branch: 'feature', source_branch: 'master').becomes(MergeRequest) }
    let(:merge_request_diff) { MergeRequest.find(merge_request.id).create_merge_request_diff }
    let(:updated_merge_request_diff) { MergeRequestDiff.find(merge_request_diff.id) }

    before do
      allow_any_instance_of(MergeRequestDiff)
        .to receive(:commits_count=).and_return(nil)
    end

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
        expect(updated_merge_request_diff.merge_request_diff_commits.count).to eq(expected_commits.count)
        expect(updated_merge_request_diff.commits.map(&:to_hash)).to eq(expected_commits)
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
        merge_request.create_merge_request_diff

        convert_to_yaml(start_id, merge_request_diff.commits, diffs_to_hashes(merge_request_diff.merge_request_diff_files))
        convert_to_yaml(stop_id, updated_merge_request_diff.commits, diffs_to_hashes(updated_merge_request_diff.merge_request_diff_files))

        MergeRequestDiffCommit.delete_all
        MergeRequestDiffFile.delete_all
      end

      context 'when BUFFER_ROWS is exceeded' do
        before do
          stub_const("#{described_class}::BUFFER_ROWS", 1)

          allow(Gitlab::Database).to receive(:bulk_insert).and_call_original
        end

        it 'inserts commit rows in chunks of BUFFER_ROWS' do
          # There are 29 commits in each diff, so we should have slices of 20 + 9 + 20 + 9.
          stub_const("#{described_class}::BUFFER_ROWS", 20)

          expect(Gitlab::Database).to receive(:bulk_insert)
                                        .with('merge_request_diff_commits', anything)
                                        .exactly(4)
                                        .times
                                        .and_call_original

          subject.perform(start_id, stop_id)
        end

        it 'inserts diff rows in chunks of DIFF_FILE_BUFFER_ROWS' do
          # There are 20 files in each diff, so we should have slices of 20 + 20.
          stub_const("#{described_class}::DIFF_FILE_BUFFER_ROWS", 20)

          expect(Gitlab::Database).to receive(:bulk_insert)
                                        .with('merge_request_diff_files', anything)
                                        .exactly(2)
                                        .times
                                        .and_call_original

          subject.perform(start_id, stop_id)
        end
      end

      context 'when BUFFER_ROWS is not exceeded' do
        it 'only updates once' do
          expect(Gitlab::Database).to receive(:bulk_insert)
                                        .with('merge_request_diff_commits', anything)
                                        .once
                                        .and_call_original

          expect(Gitlab::Database).to receive(:bulk_insert)
                                        .with('merge_request_diff_files', anything)
                                        .once
                                        .and_call_original

          subject.perform(start_id, stop_id)
        end
      end

      context 'when some rows were already inserted due to a previous failure' do
        before do
          subject.perform(start_id, stop_id)

          convert_to_yaml(start_id, merge_request_diff.commits, diffs_to_hashes(merge_request_diff.merge_request_diff_files))
          convert_to_yaml(stop_id, updated_merge_request_diff.commits, diffs_to_hashes(updated_merge_request_diff.merge_request_diff_files))
        end

        it 'does not raise' do
          expect { subject.perform(start_id, stop_id) }.not_to raise_exception
        end

        it 'logs a message' do
          expect(Rails.logger).to receive(:info)
                                    .with(
                                      a_string_matching(described_class.name).and(matching([start_id, stop_id].inspect))
                                    )
                                    .twice

          subject.perform(start_id, stop_id)
        end

        it 'ends up with the correct rows' do
          expect(updated_merge_request_diff.commits.count).to eq(29)
          expect(updated_merge_request_diff.raw_diffs.count).to eq(20)
        end
      end

      context 'when the merge request diff update fails' do
        let(:exception) { ActiveRecord::RecordNotFound }

        let(:perform_ignoring_exceptions) do
          begin
            subject.perform(start_id, stop_id)
          rescue described_class::Error
          end
        end

        before do
          allow_any_instance_of(described_class::MergeRequestDiff::ActiveRecord_Relation)
            .to receive(:update_all).and_raise(exception)
        end

        it 'raises an error' do
          expect { subject.perform(start_id, stop_id) }
            .to raise_exception(described_class::Error)
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:info).with(
            a_string_matching(described_class.name)
              .and(matching([start_id, stop_id].inspect))
              .and(matching(exception.name))
          )

          perform_ignoring_exceptions
        end

        it 'still adds diff commits' do
          expect { perform_ignoring_exceptions }
            .to change { MergeRequestDiffCommit.count }
        end

        it 'still adds diff files' do
          expect { perform_ignoring_exceptions }
            .to change { MergeRequestDiffFile.count }
        end
      end
    end

    context 'when the merge request diff has valid commits and diffs' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_commits) { commits }
      let(:diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }
      let(:expected_diffs) { diffs }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diff has diffs but no commits' do
      let(:commits) { nil }
      let(:expected_commits) { [] }
      let(:diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }
      let(:expected_diffs) { diffs }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs do not have too_large set' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_commits) { commits }
      let(:expected_diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }

      let(:diffs) do
        expected_diffs.map { |diff| diff.except(:too_large) }
      end

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs do not have a_mode and b_mode set' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_commits) { commits }
      let(:expected_diffs) { diffs_to_hashes(merge_request_diff.merge_request_diff_files) }

      let(:diffs) do
        expected_diffs.map { |diff| diff.except(:a_mode, :b_mode) }
      end

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs have binary content' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_commits) { commits }
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
      let(:expected_commits) { commits }
      let(:diffs) { [] }
      let(:expected_diffs) { diffs }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs have invalid content' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:expected_commits) { commits }
      let(:diffs) { ['--broken-diff'] }
      let(:expected_diffs) { [] }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs are Rugged::Patch instances' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:first_commit) { project.repository.commit(merge_request_diff.head_commit_sha) }
      let(:expected_commits) { commits }
      let(:diffs) { first_commit.rugged_diff_from_parent.patches }
      let(:expected_diffs) { [] }

      include_examples 'updated MR diff'
    end

    context 'when the merge request diffs are Rugged::Diff::Delta instances' do
      let(:commits) { merge_request_diff.commits.map(&:to_hash) }
      let(:first_commit) { project.repository.commit(merge_request_diff.head_commit_sha) }
      let(:expected_commits) { commits }
      let(:diffs) { first_commit.rugged_diff_from_parent.deltas }
      let(:expected_diffs) { [] }

      include_examples 'updated MR diff'
    end
  end
end
