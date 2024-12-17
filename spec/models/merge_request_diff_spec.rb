# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiff, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  include RepoHelpers

  let(:diff_with_commits) { create(:merge_request).merge_request_diff }

  describe 'validations' do
    subject { diff_with_commits }

    it { is_expected.not_to validate_uniqueness_of(:diff_type).scoped_to(:merge_request_id) }

    it 'checks sha format of base_commit_sha, head_commit_sha and start_commit_sha' do
      subject.base_commit_sha = subject.head_commit_sha = subject.start_commit_sha = 'foobar'

      expect(subject.valid?).to be false
      expect(subject.errors.count).to eq 3
      expect(subject.errors.full_messages).to all(include('is not a valid SHA'))
    end

    it 'does not validate uniqueness by default' do
      expect(build(:merge_request_diff, merge_request: subject.merge_request)).to be_valid
    end

    context 'when merge request diff is a merge_head type' do
      it 'is valid' do
        expect(build(:merge_request_diff, :merge_head, merge_request: subject.merge_request)).to be_valid
      end

      context 'when merge_head diff exists' do
        let(:existing_merge_head_diff) { create(:merge_request_diff, :merge_head) }

        it 'validates uniqueness' do
          expect(build(:merge_request_diff, :merge_head, merge_request: existing_merge_head_diff.merge_request)).not_to be_valid
        end
      end
    end
  end

  describe 'create new record' do
    subject { diff_with_commits }

    before do
      allow(Gitlab::Git::KeepAround).to receive(:execute).and_call_original
    end

    it { expect(subject).to be_valid }
    it { expect(subject).to be_persisted }
    it { expect(subject.commits.count).to eq(29) }
    it { expect(subject.diffs.count).to eq(20) }
    it { expect(subject.head_commit_sha).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0') }
    it { expect(subject.base_commit_sha).to eq('ae73cb07c9eeaf35924a10f713b364d32b2dd34f') }
    it { expect(subject.start_commit_sha).to eq('0b4bc9a49b562e85de7cc9e834518ea6828729b9') }
    it { expect(subject.patch_id_sha).to eq('f14ae956369247901117b8b7d237c9dc605898c5') }

    it 'calls GraphqlTriggers.merge_request_diff_generated' do
      merge_request = create(:merge_request, :skip_diff_creation)

      expect(GraphqlTriggers).to receive(:merge_request_diff_generated).with(merge_request)

      merge_request.create_merge_request_diff
    end

    it 'creates hidden refs' do
      hidden_refs = subject.project.repository.raw.list_refs(["refs/#{Repository::REF_MERGE_REQUEST}/", "refs/#{Repository::REF_KEEP_AROUND}/"])

      expect(hidden_refs).to match_array([
        Gitaly::ListRefsResponse::Reference.new(name: subject.merge_request.ref_path, target: subject.head_commit_sha),
        Gitaly::ListRefsResponse::Reference.new(name: "refs/#{Repository::REF_KEEP_AROUND}/#{subject.head_commit_sha}", target: subject.head_commit_sha),
        Gitaly::ListRefsResponse::Reference.new(name: "refs/#{Repository::REF_KEEP_AROUND}/#{subject.start_commit_sha}", target: subject.start_commit_sha)
      ])
    end

    context 'when diff_type is merge_head' do
      let(:merge_request) { create(:merge_request) }

      let!(:merge_head) do
        MergeRequests::MergeToRefService
          .new(project: merge_request.project, current_user: merge_request.author)
          .execute(merge_request)

        merge_request.create_merge_head_diff
      end

      it { expect(merge_head).to be_valid }
      it { expect(merge_head).to be_persisted }
      it { expect(merge_head.commits.count).to eq(30) }
      it { expect(merge_head.diffs.count).to eq(20) }
      it { expect(merge_head.head_commit_sha).to eq(merge_request.merge_ref_head.diff_refs.head_sha) }
      it { expect(merge_head.base_commit_sha).to eq(merge_request.merge_ref_head.diff_refs.base_sha) }
      it { expect(merge_head.start_commit_sha).to eq(merge_request.target_branch_sha) }

      it 'creates hidden refs' do
        hidden_refs = merge_request.project.repository.raw.list_refs(["refs/#{Repository::REF_MERGE_REQUEST}/", "refs/#{Repository::REF_KEEP_AROUND}/"])

        expect(hidden_refs).to match_array([
          Gitaly::ListRefsResponse::Reference.new(name: merge_request.ref_path, target: merge_request.source_branch_sha),
          Gitaly::ListRefsResponse::Reference.new(name: merge_request.merge_ref_path, target: merge_head.head_commit_sha),
          Gitaly::ListRefsResponse::Reference.new(name: "refs/#{Repository::REF_KEEP_AROUND}/#{merge_head.start_commit_sha}", target: merge_head.start_commit_sha),
          Gitaly::ListRefsResponse::Reference.new(name: "refs/#{Repository::REF_KEEP_AROUND}/#{merge_request.source_branch_sha}", target: merge_request.source_branch_sha)
        ])
      end
    end
  end

  describe '.by_head_commit_sha' do
    subject(:by_head_commit_sha) { described_class.by_commit_sha(sha) }

    context "with given sha equal to the diff's head_commit_sha" do
      let(:sha) { diff_with_commits.head_commit_sha }

      it 'returns the merge request diff' do
        expect(by_head_commit_sha).to eq([diff_with_commits])
      end
    end

    context "with given sha not equal to any diff's head_commit_sha" do
      let(:sha) { diff_with_commits.base_commit_sha }

      it 'returns an empty result' do
        expect(by_head_commit_sha).to be_empty
      end
    end
  end

  describe '.by_commit_sha' do
    subject(:by_commit_sha) { described_class.by_commit_sha(sha) }

    let!(:merge_request) { create(:merge_request) }

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
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:outdated) { merge_request.merge_request_diff }
    let_it_be(:latest) { merge_request.create_merge_request_diff }
    let_it_be(:merge_head) { merge_request.create_merge_head_diff }

    let_it_be(:closed_mr) { create(:merge_request, :closed_last_month) }
    let(:closed) { closed_mr.merge_request_diff }

    let_it_be(:merged_mr) { create(:merge_request, :merged_last_month) }
    let(:merged) { merged_mr.merge_request_diff }

    let_it_be(:recently_closed_mr) { create(:merge_request, :closed) }
    let(:closed_recently) { recently_closed_mr.merge_request_diff }

    let_it_be(:recently_merged_mr) { create(:merge_request, :merged) }

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

      it { is_expected.to contain_exactly(outdated.id, latest.id, closed.id, merged.id, closed_recently.id, merged_recently.id, merge_head.id) }

      it 'ignores diffs with 0 files' do
        MergeRequestDiffFile.where(merge_request_diff_id: [closed_recently.id, merged_recently.id]).delete_all
        closed_recently.update!(files_count: 0)
        merged_recently.update!(files_count: 0)

        is_expected.to contain_exactly(outdated.id, latest.id, closed.id, merged.id, merge_head.id)
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

  describe '#ensure_project_id' do
    let_it_be(:merge_request) { create(:merge_request, :without_diffs) }

    let(:diff) { build(:merge_request_diff, merge_request: merge_request, project_id: project_id) }

    subject { diff.save! }

    context 'when project_id is null' do
      let(:project_id) { nil }

      it do
        expect { subject }.to change(diff, :project_id).from(nil).to(merge_request.target_project_id)
      end
    end

    context 'when project_id is already set' do
      let(:project_id) { create(:project, :stubbed_repository).id }

      it do
        expect { subject }.not_to change(diff, :project_id)
      end
    end
  end

  describe '#update_external_diff_store' do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:diff) { merge_request.merge_request_diff }
    let(:store) { diff.external_diff.object_store }

    where(:change_stored_externally, :change_external_diff) do
      false | false
      false | true
      true  | false
      true  | true
    end

    with_them do
      it do
        diff.stored_externally = true if change_stored_externally
        diff.external_diff = "new-filename" if change_external_diff

        update_store = receive(:update_column).with(:external_diff_store, store)

        if change_stored_externally || change_external_diff
          expect(diff).to update_store
        else
          expect(diff).not_to update_store
        end

        diff.save!
      end
    end
  end

  describe '#migrate_files_to_external_storage!' do
    let(:uploader) { ExternalDiffUploader }
    let(:file_store) { uploader::Store::LOCAL }
    let(:remote_store) { uploader::Store::REMOTE }
    let(:merge_request) { create(:merge_request) }
    let(:diff) { merge_request.merge_request_diff }

    it 'converts from in-database to external file storage' do
      expect(diff).not_to be_stored_externally

      stub_external_diffs_setting(enabled: true)

      expect(diff).to receive(:save!).and_call_original

      diff.migrate_files_to_external_storage!

      expect(diff).to be_stored_externally
      expect(diff.external_diff_store).to eq(file_store)
    end

    it 'migrates a nil diff file' do
      expect(diff).not_to be_stored_externally
      MergeRequestDiffFile.where(merge_request_diff_id: diff.id).update_all(diff: nil)

      stub_external_diffs_setting(enabled: true)

      diff.migrate_files_to_external_storage!

      expect(diff).to be_stored_externally
    end

    it 'safely handles a transaction error when migrating to external storage' do
      expect(diff).not_to be_stored_externally
      expect(diff.external_diff).not_to be_exists

      stub_external_diffs_setting(enabled: true)

      expect(diff).not_to receive(:save!)
      expect(ApplicationRecord)
        .to receive(:legacy_bulk_insert)
        .with('merge_request_diff_files', anything)
        .and_raise(ActiveRecord::Rollback)

      expect { diff.migrate_files_to_external_storage! }.not_to change(diff, :merge_request_diff_files)

      diff.reload

      expect(diff).not_to be_stored_externally

      # The diff is written outside of the transaction, which is desirable to
      # avoid long transaction times when migrating, but it does mean we can
      # leave the file dangling on failure
      expect(diff.external_diff).to be_exists
    end

    it 'converts from in-database to external object storage' do
      expect(diff).not_to be_stored_externally

      stub_external_diffs_setting(enabled: true)

      # Without direct_upload: true, the files would be saved to disk, and a
      # background job would be enqueued to move the file to object storage
      stub_external_diffs_object_storage(uploader, direct_upload: true)

      expect(diff).to receive(:save!).and_call_original

      diff.migrate_files_to_external_storage!

      expect(diff).to be_stored_externally
      expect(diff.external_diff_store).to eq(remote_store)
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

    context 'diff adds an empty file' do
      let(:project) { create(:project, :test_repo) }
      let(:merge_request) do
        create(
          :merge_request,
          source_project: project,
          target_project: project,
          source_branch: 'empty-file',
          target_branch: 'master'
        )
      end

      it 'migrates the diff to object storage' do
        create_file_in_repo(project, 'master', 'empty-file', 'empty-file', '')

        expect(diff).not_to be_stored_externally

        stub_external_diffs_setting(enabled: true)
        stub_external_diffs_object_storage(uploader, direct_upload: true)

        diff.migrate_files_to_external_storage!

        expect(diff).to be_stored_externally
        expect(diff.external_diff_store).to eq(remote_store)
      end
    end
  end

  describe '#migrate_files_to_database!' do
    let(:diff) { create(:merge_request).merge_request_diff }

    it 'converts from external to in-database storage' do
      stub_external_diffs_setting(enabled: true)

      expect(diff).to be_stored_externally
      expect(diff).to receive(:update!).and_call_original

      file = diff.external_diff
      file_data = file.read
      diff.migrate_files_to_database!

      expect(diff).not_to be_stored_externally
      expect(file).not_to exist
      expect(diff.merge_request_diff_files.map(&:diff).join('')).to eq(file_data)
    end

    it 'does nothing with an in-database diff' do
      expect(diff).not_to be_stored_externally
      expect(diff).not_to receive(:update!)

      diff.migrate_files_to_database!
    end

    it 'does nothing with an empty diff' do
      stub_external_diffs_setting(enabled: true)
      MergeRequestDiffFile.where(merge_request_diff_id: diff.id).delete_all
      diff.save! # update files_count

      expect(diff).not_to receive(:update!)

      diff.migrate_files_to_database!
    end
  end

  describe '#latest?' do
    let!(:mr) { create(:merge_request) }
    let!(:first_diff) { mr.merge_request_diff }
    let!(:last_diff) { mr.create_merge_request_diff }

    it { expect(last_diff.reload).to be_latest }
    it { expect(first_diff.reload).not_to be_latest }
  end

  shared_examples_for 'merge request diffs' do
    let(:merge_request) { create(:merge_request) }

    context 'when it was not cleaned by the system' do
      let!(:diff) { merge_request.merge_request_diff.reload }

      it 'returns persisted diffs' do
        expect(diff).to receive(:load_diffs).and_call_original

        diff.diffs.diff_files
      end
    end

    context 'when diff was cleaned by the system' do
      let!(:diff) { merge_request.merge_request_diff.reload }

      before do
        diff.clean!
      end

      it 'returns diffs from repository if can compare with current diff refs' do
        expect(diff).not_to receive(:load_diffs)

        expect(Compare)
          .to receive(:new)
          .with(
            instance_of(Gitlab::Git::Compare),
            merge_request.target_project,
            base_sha: diff.base_commit_sha,
            straight: false
          )
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

    describe '#diffs_in_batch' do
      let(:diff_options) { {} }

      shared_examples_for 'measuring diffs metrics' do
        specify do
          allow(Gitlab::Metrics).to receive(:measure).and_call_original
          expect(Gitlab::Metrics).to receive(:measure).with(:diffs_reorder).and_call_original
          expect(Gitlab::Metrics).to receive(:measure).with(:diffs_collection).and_call_original

          diff_with_commits.diffs_in_batch(0, 10, diff_options: diff_options)
        end
      end

      shared_examples_for 'fetching full diffs' do
        it_behaves_like 'measuring diffs metrics'

        it 'returns diffs from repository comparison' do
          expect_next_instance_of(Compare) do |comparison|
            expect(comparison).to receive(:diffs)
              .with(diff_options)
              .and_call_original
          end

          diff_with_commits.diffs_in_batch(1, 10, diff_options: diff_options)
        end

        it 'returns a Gitlab::Diff::FileCollection::Compare with full diffs' do
          diffs = diff_with_commits.diffs_in_batch(1, 10, diff_options: diff_options)

          expect(diffs).to be_a(Gitlab::Diff::FileCollection::Compare)
          expect(diffs.diff_files.size).to be > 10
        end

        it 'returns empty pagination data' do
          diffs = diff_with_commits.diffs_in_batch(1, 10, diff_options: diff_options)

          expect(diffs.pagination_data).to eq(total_pages: nil)
        end

        it 'measures diffs_comparison' do
          allow(Gitlab::Metrics).to receive(:measure).and_call_original
          expect(Gitlab::Metrics).to receive(:measure).with(:diffs_comparison).and_call_original

          diff_with_commits.diffs_in_batch(1, 10, diff_options: diff_options)
        end
      end

      shared_examples_for 'perform generated files check' do
        it 'checks generated files' do
          diffs = diff_with_commits.diffs_in_batch(1, 10, diff_options: diff_options)

          expect(diffs.diff_files.first.generated?).to be false
        end
      end

      context 'when no persisted files available' do
        before do
          diff_with_commits.clean!
        end

        it_behaves_like 'fetching full diffs'

        context 'when diff_options include ignore_whitespace_change' do
          let(:diff_options) do
            { ignore_whitespace_change: true }
          end

          it_behaves_like 'fetching full diffs'
          it_behaves_like 'perform generated files check'
        end
      end

      context 'when persisted files available' do
        it_behaves_like 'measuring diffs metrics'

        it 'returns paginated diffs' do
          diffs = diff_with_commits.diffs_in_batch(0, 10, diff_options: diff_options)

          expect(diffs).to be_a(Gitlab::Diff::FileCollection::MergeRequestDiffBatch)
          expect(diffs.diff_files.size).to eq(10)
          expect(diffs.pagination_data).to eq(total_pages: 20)
        end

        it 'sorts diff files directory first' do
          diff_with_commits.update!(sorted: false) # Mark as unsorted so it'll re-order

          # There will be 11 returned, as we have to take into account for new and old paths
          expect(diff_with_commits.diffs_in_batch(0, 10, diff_options: diff_options).diff_paths).to eq(
            [
              'bar/branch-test.txt',
              'custom-highlighting/test.gitlab-custom',
              'encoding/iso8859.txt',
              'files/images/wm.svg',
              'files/js/commit.js.coffee',
              'files/js/commit.coffee',
              'files/lfs/lfs_object.iso',
              'files/ruby/popen.rb',
              'files/ruby/regex.rb',
              'files/.DS_Store',
              'files/whitespace'
            ])
        end

        context 'when diff_options include ignore_whitespace_change' do
          let(:diff_options) do
            { ignore_whitespace_change: true }
          end

          it_behaves_like 'perform generated files check'

          it 'returns pagination data from MergeRequestDiffBatch' do
            diffs = diff_with_commits.diffs_in_batch(1, 10, diff_options: diff_options)
            file_count = diff_with_commits.merge_request_diff_files.count

            expect(diffs).to be_a(Gitlab::Diff::FileCollection::Compare)
            expect(diffs.diff_files.size).to eq 10
            expect(diffs.pagination_data).to eq(total_pages: file_count)
          end

          it 'returns an empty MergeRequestBatch with empty pagination data when the batch is empty' do
            diffs = diff_with_commits.diffs_in_batch(30, 10, diff_options: diff_options)

            expect(diffs).to be_a(Gitlab::Diff::FileCollection::MergeRequestDiffBatch)
            expect(diffs.diff_files.size).to eq 0
            expect(diffs.pagination_data).to eq(total_pages: nil)
          end
        end
      end
    end

    describe '#paginated_diffs' do
      shared_examples 'diffs with generated files check' do
        it 'checks generated files' do
          diffs = diff_with_commits.paginated_diffs(1, 10)

          expect(diffs.diff_files.first.generated?).not_to be_nil
        end
      end

      context 'when no persisted files available' do
        before do
          diff_with_commits.clean!
        end

        it_behaves_like 'diffs with generated files check'

        it 'returns a Gitlab::Diff::FileCollection::Compare' do
          diffs = diff_with_commits.paginated_diffs(1, 10)

          expect(diffs).to be_a(Gitlab::Diff::FileCollection::Compare)
          expect(diffs.diff_files.size).to eq(10)
        end
      end

      context 'when persisted files available' do
        it_behaves_like 'diffs with generated files check'

        it 'returns paginated diffs' do
          diffs = diff_with_commits.paginated_diffs(1, 10)

          expect(diffs).to be_a(Gitlab::Diff::FileCollection::PaginatedMergeRequestDiff)
          expect(diffs.diff_files.size).to eq(10)
        end

        it 'sorts diff files directory first' do
          diff_with_commits.update!(sorted: false) # Mark as unsorted so it'll re-order

          # There will be 11 returned, as we have to take into account for new and old paths
          expect(diff_with_commits.paginated_diffs(1, 10).diff_paths).to eq(
            [
              'bar/branch-test.txt',
              'custom-highlighting/test.gitlab-custom',
              'encoding/iso8859.txt',
              'files/images/wm.svg',
              'files/js/commit.js.coffee',
              'files/js/commit.coffee',
              'files/lfs/lfs_object.iso',
              'files/ruby/popen.rb',
              'files/ruby/regex.rb',
              'files/.DS_Store',
              'files/whitespace'
            ])
        end
      end
    end

    describe '#diffs' do
      let(:diff_options) { {} }

      shared_examples_for 'fetching full diffs' do
        it 'returns diffs from repository comparison' do
          expect_next_instance_of(Compare) do |comparison|
            expect(comparison).to receive(:diffs)
              .with(diff_options)
              .and_call_original
          end

          diff_with_commits.diffs(diff_options)
        end

        it 'returns a Gitlab::Diff::FileCollection::Compare with full diffs' do
          diffs = diff_with_commits.diffs(diff_options)

          expect(diffs).to be_a(Gitlab::Diff::FileCollection::Compare)
          expect(diffs.diff_files.size).to eq(20)
        end
      end

      context 'when no persisted files available' do
        before do
          diff_with_commits.clean!
        end

        it_behaves_like 'fetching full diffs'
      end

      context 'when diff_options include ignore_whitespace_change' do
        it_behaves_like 'fetching full diffs' do
          let(:diff_options) do
            { ignore_whitespace_change: true }
          end
        end
      end

      context 'when persisted files available' do
        it 'returns diffs' do
          diffs = diff_with_commits.diffs(diff_options)

          expect(diffs).to be_a(Gitlab::Diff::FileCollection::MergeRequestDiff)
          expect(diffs.diff_files.size).to eq(20)
        end

        it 'sorts diff files directory first' do
          diff_with_commits.update!(sorted: false) # Mark as unsorted so it'll re-order

          expect(diff_with_commits.diffs(diff_options).diff_paths).to eq(
            [
              'bar/branch-test.txt',
              'custom-highlighting/test.gitlab-custom',
              'encoding/iso8859.txt',
              'files/images/wm.svg',
              'files/js/commit.js.coffee',
              'files/js/commit.coffee',
              'files/lfs/lfs_object.iso',
              'files/ruby/popen.rb',
              'files/ruby/regex.rb',
              'files/.DS_Store',
              'files/whitespace',
              'foo/bar/.gitkeep',
              'with space/README.md',
              '.DS_Store',
              '.gitattributes',
              '.gitignore',
              '.gitmodules',
              'CHANGELOG',
              'README',
              'gitlab-grack',
              'gitlab-shell'
            ])
        end
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

    describe "#set_patch_id_sha" do
      let(:mr_diff) { create(:merge_request).merge_request_diff }

      it "sets the patch_id_sha attribute" do
        expect(mr_diff.set_patch_id_sha).not_to be_nil
      end

      context "when base_commit_sha is nil" do
        it "records patch_id_sha as nil" do
          expect(mr_diff).to receive(:base_commit_sha).and_return(nil)

          expect(mr_diff.set_patch_id_sha).to be_nil
        end
      end

      context "when head_commit_sha is nil" do
        it "records patch_id_sha as nil" do
          expect(mr_diff).to receive(:head_commit_sha).and_return(nil)

          expect(mr_diff.set_patch_id_sha).to be_nil
        end
      end

      context "when head_commit_sha and base_commit_sha match" do
        it "records patch_id_sha as nil" do
          expect(mr_diff).to receive(:base_commit_sha).at_least(:once).and_return("abc123")
          expect(mr_diff).to receive(:head_commit_sha).at_least(:once).and_return("abc123")

          expect(mr_diff.set_patch_id_sha).to be_nil
        end
      end
    end

    describe '#get_patch_id_sha' do
      let(:mr_diff) { create(:merge_request).merge_request_diff }

      context 'when the patch_id exists on the model' do
        it 'returns the patch_id' do
          expect(mr_diff.patch_id_sha).not_to be_nil
          expect(mr_diff.get_patch_id_sha).to eq(mr_diff.patch_id_sha)
        end
      end

      context 'when the patch_id does not exist on the model' do
        it 'retrieves the patch id, saves the model, and returns it' do
          expect(mr_diff.patch_id_sha).not_to be_nil

          patch_id = mr_diff.patch_id_sha
          mr_diff.update!(patch_id_sha: nil)

          expect(mr_diff.get_patch_id_sha).to eq(patch_id)
          expect(mr_diff.reload.patch_id_sha).to eq(patch_id)
        end

        context 'when base_sha is nil' do
          before do
            mr_diff.update!(patch_id_sha: nil)
            allow(mr_diff).to receive(:base_commit_sha).and_return(nil)
          end

          it 'returns nil' do
            expect(mr_diff.reload.get_patch_id_sha).to be_nil
          end
        end

        context 'when head_sha is nil' do
          before do
            mr_diff.update!(patch_id_sha: nil)
            allow(mr_diff).to receive(:head_commit_sha).and_return(nil)
          end

          it 'returns nil' do
            expect(mr_diff.reload.get_patch_id_sha).to be_nil
          end
        end

        context 'when base_sha and head_sha dont match' do
          before do
            mr_diff.update!(patch_id_sha: nil)
            allow(mr_diff).to receive(:head_commit_sha).and_return('123123')
            allow(mr_diff).to receive(:base_commit_sha).and_return('43121')
          end

          it 'returns nil' do
            expect(mr_diff.reload.get_patch_id_sha).to be_nil
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

      it 'persists diff files sorted directory first' do
        mr_diff = create(:merge_request).merge_request_diff
        diff_files_paths = mr_diff.merge_request_diff_files.map { |file| file.new_path.presence || file.old_path }

        expect(diff_files_paths).to eq(
          [
            'bar/branch-test.txt',
            'custom-highlighting/test.gitlab-custom',
            'encoding/iso8859.txt',
            'files/images/wm.svg',
            'files/js/commit.coffee',
            'files/lfs/lfs_object.iso',
            'files/ruby/popen.rb',
            'files/ruby/regex.rb',
            'files/.DS_Store',
            'files/whitespace',
            'foo/bar/.gitkeep',
            'with space/README.md',
            '.DS_Store',
            '.gitattributes',
            '.gitignore',
            '.gitmodules',
            'CHANGELOG',
            'README',
            'gitlab-grack',
            'gitlab-shell'
          ])
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
        let(:content) { ("a" * 10000) + "\x00" }
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

      context 'handling generated files' do
        let(:project) do
          create(:project, :custom_repo, files: {
            '.gitattributes' => '*.txt gitlab-generated'
          })
        end

        let(:generated_file_name_manual) { 'generated.txt' }
        let(:generated_file_name_auto) { 'package-lock.json' }
        let(:regular_file_name) { 'regular.rb' }

        let(:target_branch) { project.default_branch }
        let(:source_branch) { 'test-generated-diff-file' }

        let(:merge_request) do
          create(
            :merge_request,
            target_project: project,
            source_project: project,
            source_branch: source_branch,
            target_branch: target_branch
          )
        end

        let(:diff_files) do
          merge_request.merge_request_diff.merge_request_diff_files
        end

        before do
          project.repository.create_branch(source_branch, target_branch)

          project.repository.create_file(
            project.creator,
            generated_file_name_manual,
            'updated generated content',
            message: 'Update generated file',
            branch_name: source_branch)

          project.repository.create_file(
            project.creator,
            generated_file_name_auto,
            'updated generated content',
            message: 'Update generated file',
            branch_name: source_branch)

          project.repository.create_file(
            project.creator,
            regular_file_name,
            'updated regular content',
            message: "Update regular file",
            branch_name: source_branch)
        end

        it 'sets generated field correctly' do
          expect(diff_files.find_by(new_path: generated_file_name_manual)).to be_generated
          expect(diff_files.find_by(new_path: generated_file_name_auto)).to be_generated
          expect(diff_files.find_by(new_path: regular_file_name)).not_to be_generated
        end
      end
    end
  end

  describe 'internal diffs configured' do
    include_examples 'merge request diffs'
  end

  describe 'external diffs on disk always enabled' do
    before do
      stub_external_diffs_setting(enabled: true, when: 'always')
    end

    include_examples 'merge request diffs'
  end

  describe 'external diffs in object storage always enabled' do
    let(:uploader) { ExternalDiffUploader }
    let(:remote_store) { uploader::Store::REMOTE }

    subject(:diff) { merge_request.merge_request_diff }

    before do
      stub_external_diffs_setting(enabled: true, when: 'always')
      stub_external_diffs_object_storage(uploader, direct_upload: true)
    end

    # We can't use the full merge request diffs shared examples here because
    # reading from the fake object store isn't implemented yet

    context 'empty diff' do
      let(:merge_request) { create(:merge_request, :without_diffs) }

      it 'creates an empty diff' do
        expect(diff.state).to eq('empty')
        expect(diff).not_to be_stored_externally
      end
    end

    context 'normal diff' do
      let(:merge_request) { create(:merge_request) }

      it 'creates a diff in object storage' do
        expect(diff).to be_stored_externally
        expect(diff.state).to eq('collected')
        expect(diff.external_diff_store).to eq(remote_store)
      end
    end

    context 'diff adding an empty file' do
      let(:project) { create(:project, :test_repo) }
      let(:merge_request) do
        create(
          :merge_request,
          source_project: project,
          target_project: project,
          source_branch: 'empty-file',
          target_branch: 'master'
        )
      end

      it 'creates a diff in object storage' do
        create_file_in_repo(project, 'master', 'empty-file', 'empty-file', '')

        diff.reload

        expect(diff).to be_stored_externally
        expect(diff.state).to eq('collected')
        expect(diff.external_diff_store).to eq(remote_store)
      end
    end
  end

  describe 'exernal diffs enabled for outdated diffs' do
    before do
      stub_external_diffs_setting(enabled: true, when: 'outdated')
    end

    include_examples 'merge request diffs'

    it 'stores up-to-date diffs in the database' do
      diff = merge_request.merge_request_diff.reload
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
      old_diff = merge_request.merge_request_diff.reload

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

    shared_examples 'limited number of shas' do
      it 'returns limited number of shas' do
        expect(diff_with_commits.commit_shas(limit: 2).size).to eq(2)
        expect(diff_with_commits.commit_shas(limit: 100).size).to eq(29)
        expect(diff_with_commits.commit_shas.size).to eq(29)
      end
    end

    context 'with limit attribute' do
      it_behaves_like 'limited number of shas'
    end

    context 'with preloaded diff commits' do
      before do
        # preloads the merge_request_diff_commits association
        diff_with_commits.merge_request_diff_commits.to_a
      end

      it_behaves_like 'limited number of shas'

      it 'does not trigger any query' do
        count = ActiveRecord::QueryRecorder.new { diff_with_commits.commit_shas(limit: 2) }.count

        expect(count).to eq(0)
      end
    end
  end

  describe '#commits_count' do
    it 'returns number of commits using serialized commits' do
      expect(diff_with_commits.commits_count).to eq(29)
    end
  end

  describe '#files_count' do
    let_it_be(:merge_request) { create(:merge_request) }

    let(:diff) { merge_request.merge_request_diff }
    let(:actual_count) { diff.merge_request_diff_files.count }

    it 'is set by default' do
      expect(diff.read_attribute(:files_count)).to eq(actual_count)
    end

    it 'is set to the sentinel value if the actual value exceeds it' do
      stub_const("#{described_class}::FILES_COUNT_SENTINEL", actual_count - 1)

      diff.save! # update the files_count column with the stub in place

      expect(diff.read_attribute(:files_count)).to eq(described_class::FILES_COUNT_SENTINEL)
    end

    it 'uses the cached count if present' do
      diff.update_columns(files_count: actual_count + 1)

      expect(diff.files_count).to eq(actual_count + 1)
    end

    it 'uses the actual count if nil' do
      diff.update_columns(files_count: nil)

      expect(diff.files_count).to eq(actual_count)
    end

    it 'uses the actual count if overflown' do
      diff.update_columns(files_count: described_class::FILES_COUNT_SENTINEL)

      expect(diff.files_count).to eq(actual_count)
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
      expect(subject.includes_any_commits?([Gitlab::Git::SHA1_BLANK_SHA])).to eq(false)
    end

    it 'returns true if passed commits exists' do
      args_with_existing_commits = non_existent_shas << subject.head_commit_sha

      expect(subject.includes_any_commits?(args_with_existing_commits)).to eq(true)
    end
  end

  describe '#modified_paths' do
    subject do
      create(:merge_request_diff).tap do |diff|
        create(:merge_request_diff_file, :new_file, merge_request_diff: diff)
        create(:merge_request_diff_file, :renamed_file, merge_request_diff: diff)

        diff.merge_request_diff_files.reset
      end
    end

    it 'returns affected file paths' do
      expect(subject.modified_paths).to eq(%w[foo bar baz])
    end

    context "when fallback_on_overflow is true" do
      let(:merge_request) { create(:merge_request, source_branch: 'feature', target_branch: 'master') }
      let(:diff) { merge_request.merge_request_diff }

      context "when the merge_request_diff is overflowed" do
        before do
          expect(diff).to receive(:overflow?).and_return(true)
        end

        it "returns file paths via project.repository#diff_stats" do
          expect(diff.project.repository).to receive(:diff_stats).and_call_original

          expect(
            diff.modified_paths(fallback_on_overflow: true)
          ).to eq(diff.modified_paths)
        end
      end

      context "when the merge_request_diff is not overflowed" do
        before do
          expect(subject).to receive(:overflow?).and_return(false)
        end

        it "returns expect file paths withoout called #modified_paths_for_overflowed_mr" do
          expect(subject.project.repository).not_to receive(:diff_stats)

          expect(
            subject.modified_paths(fallback_on_overflow: true)
          ).to eq(subject.modified_paths)
        end
      end
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

  describe '#commits' do
    include ProjectForksHelper

    let_it_be(:target) { create(:project, :test_repo) }
    let_it_be(:forked) { fork_project(target, nil, repository: true) }
    let_it_be(:mr) { create(:merge_request, source_project: forked, target_project: target) }

    it 'returns a CommitCollection whose container points to the target project' do
      expect(mr.merge_request_diff.commits.container).to eq(target)
    end

    it 'returns a non-empty CommitCollection' do
      expect(mr.merge_request_diff.commits.commits.size).to be > 0
    end

    context 'with a page' do
      it 'returns a limited number of commits for page' do
        expect(mr.merge_request_diff.commits(limit: 1, page: 1).map(&:sha)).to eq(
          %w[
            b83d6e391c22777fca1ed3012fce84f633d7fed0
          ])
        expect(mr.merge_request_diff.commits(limit: 1, page: 2).map(&:sha)).to eq(
          %w[
            498214de67004b1da3d820901307bed2a68a8ef6
          ])
      end
    end
  end

  describe '.latest_diff_for_merge_requests' do
    let_it_be(:merge_request_1) { create(:merge_request, :skip_diff_creation) }
    let_it_be(:merge_request_1_diff_1) { create(:merge_request_diff, merge_request: merge_request_1, created_at: 3.days.ago) }
    let_it_be(:merge_request_1_diff_2) { create(:merge_request_diff, merge_request: merge_request_1, created_at: 1.day.ago) }

    let_it_be(:merge_request_2) { create(:merge_request, :skip_diff_creation) }
    let_it_be(:merge_request_2_diff_1) { create(:merge_request_diff, merge_request: merge_request_2, created_at: 3.days.ago) }

    let_it_be(:merge_request_3) { create(:merge_request, :skip_diff_creation) }

    subject { described_class.latest_diff_for_merge_requests([merge_request_1, merge_request_2]) }

    it 'loads the latest merge_request_diff record for the given merge requests' do
      expect(subject).to match_array([merge_request_1_diff_2, merge_request_2_diff_1])
    end

    it 'loads nothing if the merge request has no diff record' do
      expect(described_class.latest_diff_for_merge_requests(merge_request_3)).to be_empty
    end

    it 'loads nothing if nil was passed as merge_request' do
      expect(described_class.latest_diff_for_merge_requests(nil)).to be_empty
    end
  end

  context 'external diff caching' do
    let(:test_dir) { 'tmp/tests/external-diffs' }
    let(:cache_dir) { File.join(Dir.tmpdir, "project-#{diff.project.id}-external-mr-#{diff.merge_request_id}-diff-#{diff.id}-cache") }
    let(:cache_filepath) { File.join(cache_dir, "diff-#{diff.id}") }
    let(:external_diff_content) { diff.opening_external_diff { |diff| diff.read } }

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

    subject(:diff) { diff_with_commits }

    describe '#cached_external_diff' do
      context 'when diff is externally stored' do
        context 'when diff is already cached' do
          it 'yields cached file' do
            Dir.mkdir(cache_dir)
            File.open(cache_filepath, 'wb') { |f| f.write(external_diff_content) }

            expect(diff).not_to receive(:cache_external_diff)

            expect { |b| diff.cached_external_diff(&b) }.to yield_with_args(File)
          end
        end

        context 'when diff is not cached' do
          it 'caches external diff in tmp storage' do
            expect(diff).to receive(:cache_external_diff).and_call_original
            expect(File.exist?(cache_filepath)).to eq(false)
            expect { |b| diff.cached_external_diff(&b) }.to yield_with_args(File)
            expect(File.exist?(cache_filepath)).to eq(true)
            expect(File.read(cache_filepath)).to eq(external_diff_content)
          end
        end
      end

      context 'when diff is not externally stored' do
        it 'yields nil' do
          stub_external_diffs_setting(enabled: false)

          expect { |b| diff.cached_external_diff(&b) }.to yield_with_args(nil)
        end
      end
    end

    describe '#remove_cached_external_diff' do
      before do
        diff.cached_external_diff { |diff| diff }
      end

      it 'removes external diff cache diff' do
        expect(Dir.exist?(cache_dir)).to eq(true)

        diff.remove_cached_external_diff

        expect(Dir.exist?(cache_dir)).to eq(false)
      end

      context 'when path is traversed' do
        it 'raises' do
          allow(diff).to receive(:external_diff_cache_dir).and_return(File.join(cache_dir, '..'))

          expect { diff.remove_cached_external_diff }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path')
        end
      end

      context 'when path is not allowed' do
        it 'raises' do
          allow(diff).to receive(:external_diff_cache_dir).and_return('/')

          expect { diff.remove_cached_external_diff }.to raise_error(StandardError, 'path / is not allowed')
        end
      end

      context 'when dir does not exist' do
        it 'returns' do
          FileUtils.rm_rf(cache_dir)

          expect(Dir.exist?(cache_dir)).to eq(false)
          expect(FileUtils).not_to receive(:rm_rf).with(cache_dir)

          diff.remove_cached_external_diff
        end
      end
    end
  end

  describe '#has_encoded_file_paths?' do
    context 'when there are diff files with encoded_file_path as true' do
      let(:merge_request_diff) do
        create(:merge_request_diff).tap do |diff|
          create(:merge_request_diff_file, :new_file, merge_request_diff: diff, encoded_file_path: true)
          create(:merge_request_diff_file, :renamed_file, merge_request_diff: diff, encoded_file_path: false)

          diff.merge_request_diff_files.reset
        end
      end

      it 'returns true' do
        expect(merge_request_diff.has_encoded_file_paths?).to eq(true)
      end
    end

    context 'when there are no diff files with encoded_file_path as true' do
      let(:merge_request_diff) do
        create(:merge_request_diff).tap do |diff|
          create(:merge_request_diff_file, :new_file, merge_request_diff: diff, encoded_file_path: false)
          create(:merge_request_diff_file, :renamed_file, merge_request_diff: diff, encoded_file_path: false)

          diff.merge_request_diff_files.reset
        end
      end

      it 'returns false' do
        expect(merge_request_diff.has_encoded_file_paths?).to eq(false)
      end
    end
  end
end
