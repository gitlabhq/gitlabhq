# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestDiff do
  include RepoHelpers

  let(:diff_with_commits) { create(:merge_request).merge_request_diff }

  describe 'validations' do
    subject { diff_with_commits }

    it 'checks sha format of base_commit_sha, head_commit_sha and start_commit_sha' do
      subject.base_commit_sha = subject.head_commit_sha = subject.start_commit_sha = 'foobar'

      expect(subject.valid?).to be false
      expect(subject.errors.count).to eq 3
      expect(subject.errors).to all(include('is not a valid SHA'))
    end
  end

  describe 'create new record' do
    subject { diff_with_commits }

    it { expect(subject).to be_valid }
    it { expect(subject).to be_persisted }
    it { expect(subject.commits.count).to eq(29) }
    it { expect(subject.diffs.count).to eq(20) }
    it { expect(subject.head_commit_sha).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0') }
    it { expect(subject.base_commit_sha).to eq('ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }
    it { expect(subject.start_commit_sha).to eq('0b4bc9a49b562e85de7cc9e834518ea6828729b9') }
  end

  describe '.by_commit_sha' do
    subject(:by_commit_sha) { described_class.by_commit_sha(sha) }

    let!(:merge_request) { create(:merge_request, :with_diffs) }

    context 'with sha contained in' do
      let(:sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

      it 'returns merge request diffs' do
        expect(by_commit_sha).to eq([merge_request.merge_request_diff])
      end
    end

    context 'with sha not contained in' do
      let(:sha) { 'b83d6e3' }

      it 'returns empty result' do
        expect(by_commit_sha).to be_empty
      end
    end
  end

  describe '.ids_for_external_storage_migration' do
    set(:merge_request) { create(:merge_request) }
    set(:outdated) { merge_request.merge_request_diff }
    set(:latest) { merge_request.create_merge_request_diff }

    set(:closed_mr) { create(:merge_request, :closed_last_month) }
    let(:closed) { closed_mr.merge_request_diff }

    set(:merged_mr) { create(:merge_request, :merged_last_month) }
    let(:merged) { merged_mr.merge_request_diff }

    set(:recently_closed_mr) { create(:merge_request, :closed) }
    let(:closed_recently) { recently_closed_mr.merge_request_diff }

    set(:recently_merged_mr) { create(:merge_request, :merged) }
    let(:merged_recently) { recently_merged_mr.merge_request_diff }

    before do
      merge_request.update!(latest_merge_request_diff: latest)
    end

    subject { described_class.ids_for_external_storage_migration(limit: 1000) }

    context 'external diffs are disabled' do
      before do
        stub_external_diffs_setting(enabled: false)
      end

      it { is_expected.to be_empty }
    end

    context 'external diffs are misconfigured' do
      before do
        stub_external_diffs_setting(enabled: true, when: 'every second tuesday')
      end

      it { is_expected.to be_empty }
    end

    context 'external diffs are enabled unconditionally' do
      before do
        stub_external_diffs_setting(enabled: true)
      end

      it { is_expected.to contain_exactly(outdated.id, latest.id, closed.id, merged.id, closed_recently.id, merged_recently.id) }

      it 'ignores diffs with 0 files' do
        MergeRequestDiffFile.where(merge_request_diff_id: [closed_recently.id, merged_recently.id]).delete_all

        is_expected.to contain_exactly(outdated.id, latest.id, closed.id, merged.id)
      end
    end

    context 'external diffs are enabled for outdated diffs' do
      before do
        stub_external_diffs_setting(enabled: true, when: 'outdated')
      end

      it 'returns records for outdated merge request versions' do
        is_expected.to contain_exactly(outdated.id, closed.id, merged.id)
      end
    end

    context 'with limit' do
      it 'respects the limit' do
        stub_external_diffs_setting(enabled: true)

        expect(described_class.ids_for_external_storage_migration(limit: 3).count).to eq(3)
      end
    end
  end

  describe '#migrate_files_to_external_storage!' do
    let(:diff) { create(:merge_request).merge_request_diff }

    it 'converts from in-database to external storage' do
      expect(diff).not_to be_stored_externally

      stub_external_diffs_setting(enabled: true)
      expect(diff).to receive(:save!)

      diff.migrate_files_to_external_storage!

      expect(diff).to be_stored_externally
    end

    it 'does nothing with an external diff' do
      stub_external_diffs_setting(enabled: true)

      expect(diff).to be_stored_externally
      expect(diff).not_to receive(:save!)

      diff.migrate_files_to_external_storage!
    end

    it 'does nothing if external diffs are disabled' do
      expect(diff).not_to be_stored_externally
      expect(diff).not_to receive(:save!)

      diff.migrate_files_to_external_storage!
    end
  end

  describe '#latest?' do
    let!(:mr) { create(:merge_request, :with_diffs) }
    let!(:first_diff) { mr.merge_request_diff }
    let!(:last_diff) { mr.create_merge_request_diff }

    it { expect(last_diff.reload).to be_latest }
    it { expect(first_diff.reload).not_to be_latest }
  end

  shared_examples_for 'merge request diffs' do
    let(:merge_request) { create(:merge_request, :with_diffs) }
    let!(:diff) { merge_request.merge_request_diff.reload }

    context 'when it was not cleaned by the system' do
      it 'returns persisted diffs' do
        expect(diff).to receive(:load_diffs).and_call_original

        diff.diffs.diff_files
      end
    end

    context 'when diff was cleaned by the system' do
      before do
        diff.clean!
      end

      it 'returns diffs from repository if can compare with current diff refs' do
        expect(diff).not_to receive(:load_diffs)

        expect(Compare)
          .to receive(:new)
          .with(instance_of(Gitlab::Git::Compare), merge_request.target_project,
                base_sha: diff.base_commit_sha, straight: false)
          .and_call_original

        diff.diffs
      end

      it 'returns persisted diffs if cannot compare with diff refs' do
        expect(diff).to receive(:load_diffs).and_call_original

        diff.update!(head_commit_sha: Digest::SHA1.hexdigest(SecureRandom.hex))

        diff.diffs.diff_files
      end

      it 'returns persisted diffs if diff refs does not exist' do
        expect(diff).to receive(:load_diffs).and_call_original

        diff.update!(start_commit_sha: nil, base_commit_sha: nil)

        diff.diffs.diff_files
      end
    end

    describe '#raw_diffs' do
      context 'when the :ignore_whitespace_change option is set' do
        it 'creates a new compare object instead of using preprocessed data' do
          expect(diff_with_commits).not_to receive(:load_diffs)
          expect(diff_with_commits.compare).to receive(:diffs).and_call_original

          diff_with_commits.raw_diffs(ignore_whitespace_change: true)
        end
      end

      context 'when the raw diffs are empty' do
        before do
          MergeRequestDiffFile.where(merge_request_diff_id: diff_with_commits.id).delete_all
        end

        it 'returns an empty DiffCollection' do
          expect(diff_with_commits.raw_diffs).to be_a(Gitlab::Git::DiffCollection)
          expect(diff_with_commits.raw_diffs).to be_empty
        end
      end

      context 'when the raw diffs exist' do
        it 'returns the diffs' do
          expect(diff_with_commits.raw_diffs).to be_a(Gitlab::Git::DiffCollection)
          expect(diff_with_commits.raw_diffs).not_to be_empty
        end

        context 'when the :paths option is set' do
          let(:diffs) { diff_with_commits.raw_diffs(paths: ['files/ruby/popen.rb', 'files/ruby/popen.rb']) }

          it 'only returns diffs that match the (old path, new path) given' do
            expect(diffs.map(&:new_path)).to contain_exactly('files/ruby/popen.rb')
          end

          it 'only serializes diff files found by query' do
            expect(diff_with_commits.merge_request_diff_files.count).to be > 10
            expect_any_instance_of(MergeRequestDiffFile).to receive(:to_hash).once

            diffs
          end

          it 'uses the preprocessed diffs' do
            expect(diff_with_commits).to receive(:load_diffs)

            diffs
          end
        end
      end
    end

    describe '#save_diffs' do
      it 'saves collected state' do
        mr_diff = create(:merge_request).merge_request_diff

        expect(mr_diff.collected?).to be_truthy
      end

      it 'saves overflow state' do
        allow(Commit).to receive(:max_diff_options)
          .and_return(max_lines: 0, max_files: 0)

        mr_diff = create(:merge_request).merge_request_diff

        expect(mr_diff.overflow?).to be_truthy
      end

      it 'saves empty state' do
        allow_any_instance_of(described_class).to receive_message_chain(:compare, :commits)
          .and_return([])

        mr_diff = create(:merge_request).merge_request_diff

        expect(mr_diff.empty?).to be_truthy
      end

      it 'expands collapsed diffs before saving' do
        mr_diff = create(:merge_request, source_branch: 'expand-collapse-lines', target_branch: 'master').merge_request_diff
        diff_file = mr_diff.merge_request_diff_files.find_by(new_path: 'expand-collapse/file-5.txt')

        expect(diff_file.diff).not_to be_empty
      end

      it 'saves binary diffs correctly' do
        path = 'files/images/icn-time-tracking.pdf'
        mr_diff = create(:merge_request, source_branch: 'add-pdf-text-binary', target_branch: 'master').merge_request_diff
        diff_file = mr_diff.merge_request_diff_files.find_by(new_path: path)

        expect(diff_file).to be_binary
        expect(diff_file.diff).to eq(mr_diff.compare.diffs(paths: [path]).to_a.first.diff)
      end

      context 'with diffs that contain a null byte' do
        let(:filename) { 'test-null.txt' }
        let(:content) { "a" * 10000 + "\x00" }
        let(:project) { create(:project, :repository) }
        let(:branch) { 'null-data' }
        let(:target_branch) { 'master' }

        it 'saves diffs correctly' do
          create_file_in_repo(project, target_branch, branch, filename, content)

          mr_diff = create(:merge_request, target_project: project, source_project: project, source_branch: branch, target_branch: target_branch).merge_request_diff
          diff_file = mr_diff.merge_request_diff_files.find_by(new_path: filename)

          expect(diff_file).to be_binary
          expect(diff_file.diff).to eq(mr_diff.compare.diffs(paths: [filename]).to_a.first.diff)
          expect(diff_file.diff).to include(content)
        end
      end
    end
  end

  describe 'internal diffs configured' do
    include_examples 'merge request diffs'
  end

  describe 'external diffs always enabled' do
    before do
      stub_external_diffs_setting(enabled: true, when: 'always')
    end

    include_examples 'merge request diffs'
  end

  describe 'exernal diffs enabled for outdated diffs' do
    before do
      stub_external_diffs_setting(enabled: true, when: 'outdated')
    end

    include_examples 'merge request diffs'

    it 'stores up-to-date diffs in the database' do
      expect(diff).not_to be_stored_externally
    end

    it 'stores diffs for recently closed MRs in the database' do
      mr = create(:merge_request, :closed)

      expect(mr.merge_request_diff).not_to be_stored_externally
    end

    it 'stores diffs for recently merged MRs in the database' do
      mr = create(:merge_request, :merged)

      expect(mr.merge_request_diff).not_to be_stored_externally
    end

    it 'stores diffs for old MR versions in external storage' do
      old_diff = diff
      merge_request.create_merge_request_diff
      old_diff.migrate_files_to_external_storage!

      expect(old_diff).to be_stored_externally
    end

    it 'stores diffs for old closed MRs in external storage' do
      mr = create(:merge_request, :closed_last_month)

      expect(mr.merge_request_diff).to be_stored_externally
    end

    it 'stores diffs for old merged MRs in external storage' do
      mr = create(:merge_request, :merged_last_month)

      expect(mr.merge_request_diff).to be_stored_externally
    end
  end

  describe '#commit_shas' do
    it 'returns all commit SHAs using commits from the DB' do
      expect(diff_with_commits.commit_shas).not_to be_empty
      expect(diff_with_commits.commit_shas).to all(match(/\h{40}/))
    end

    context 'with limit attribute' do
      it 'returns limited number of shas' do
        expect(diff_with_commits.commit_shas(limit: 2).size).to eq(2)
        expect(diff_with_commits.commit_shas(limit: 100).size).to eq(29)
        expect(diff_with_commits.commit_shas.size).to eq(29)
      end
    end
  end

  describe '#compare_with' do
    it 'delegates compare to the service' do
      expect(CompareService).to receive(:new).and_call_original

      diff_with_commits.compare_with(nil)
    end

    it 'uses git diff A..B approach by default' do
      diffs = diff_with_commits.compare_with('0b4bc9a49b562e85de7cc9e834518ea6828729b9').diffs

      expect(diffs.size).to eq(21)
    end
  end

  describe '#commits_count' do
    it 'returns number of commits using serialized commits' do
      expect(diff_with_commits.commits_count).to eq(29)
    end
  end

  describe '#first_commit' do
    it 'returns first commit' do
      expect(diff_with_commits.first_commit.sha).to eq(diff_with_commits.merge_request_diff_commits.last.sha)
    end
  end

  describe '#last_commit' do
    it 'returns last commit' do
      expect(diff_with_commits.last_commit.sha).to eq(diff_with_commits.merge_request_diff_commits.first.sha)
    end
  end

  describe '#includes_any_commits?' do
    let(:non_existent_shas) do
      Array.new(30) { Digest::SHA1.hexdigest(SecureRandom.hex) }
    end

    subject { diff_with_commits }

    context 'processes the passed shas in batches' do
      context 'number of existing commits is greater than batch size' do
        it 'performs a separate request for each batch' do
          stub_const('MergeRequestDiff::BATCH_SIZE', 5)

          commit_shas = subject.commit_shas

          query_count = ActiveRecord::QueryRecorder.new do
            subject.includes_any_commits?(non_existent_shas + commit_shas)
          end.count

          expect(query_count).to eq(7)
        end
      end
    end

    it 'returns false if passed commits do not exist' do
      expect(subject.includes_any_commits?([])).to eq(false)
      expect(subject.includes_any_commits?([Gitlab::Git::BLANK_SHA])).to eq(false)
    end

    it 'returns true if passed commits exists' do
      args_with_existing_commits = non_existent_shas << subject.head_commit_sha

      expect(subject.includes_any_commits?(args_with_existing_commits)).to eq(true)
    end
  end

  describe '#modified_paths' do
    subject do
      diff = create(:merge_request_diff)
      create(:merge_request_diff_file, :new_file, merge_request_diff: diff)
      create(:merge_request_diff_file, :renamed_file, merge_request_diff: diff)
      diff
    end

    it 'returns affected file paths' do
      expect(subject.modified_paths).to eq(%w{foo bar baz})
    end
  end

  describe '#opening_external_diff' do
    subject(:diff) { diff_with_commits }

    context 'external diffs disabled' do
      it { expect(diff.external_diff).not_to be_exists }

      it 'yields nil' do
        expect { |b| diff.opening_external_diff(&b) }.to yield_with_args(nil)
      end
    end

    context 'external diffs enabled' do
      let(:test_dir) { 'tmp/tests/external-diffs' }

      around do |example|
        FileUtils.mkdir_p(test_dir)

        begin
          example.run
        ensure
          FileUtils.rm_rf(test_dir)
        end
      end

      before do
        stub_external_diffs_setting(enabled: true, storage_path: test_dir)
      end

      it { expect(diff.external_diff).to be_exists }

      it 'yields an open file' do
        expect { |b| diff.opening_external_diff(&b) }.to yield_with_args(File)
      end

      it 'is re-entrant' do
        outer_file_a =
          diff.opening_external_diff do |outer_file|
            diff.opening_external_diff do |inner_file|
              expect(outer_file).to eq(inner_file)
            end

            outer_file
          end

        diff.opening_external_diff do |outer_file_b|
          expect(outer_file_a).not_to eq(outer_file_b)
        end
      end
    end
  end

  describe '#lines_count' do
    subject { diff_with_commits }

    it 'returns sum of all changed lines count in diff files' do
      expect(subject.lines_count).to eq 189
    end
  end
end
