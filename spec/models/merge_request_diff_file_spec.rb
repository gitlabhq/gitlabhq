# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffFile, feature_category: :code_review_workflow do
  it_behaves_like 'a BulkInsertSafe model', described_class do
    let(:valid_items_for_bulk_insertion) do
      build_list(:merge_request_diff_file, 10) do |mr_diff_file|
        mr_diff_file.merge_request_diff = create(:merge_request_diff)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  let(:file) { create(:merge_request).merge_request_diff.merge_request_diff_files.first }
  let(:packed) { [unpacked].pack('m0') }
  let(:unpacked) { 'unpacked' }

  # rubocop:disable Database/MultipleDatabases -- This is a test for a partitioned table, which doesn't have an ActiveRecord model
  def load_partitioned_mrdf(mrd_id)
    ActiveRecord::Base.connection.execute(
      "SELECT * FROM merge_request_diff_files_99208b8fac WHERE merge_request_diff_id = #{mrd_id}"
    )
  end
  # rubocop:enable Database/MultipleDatabases

  describe 'data migration to partitioned table' do
    let(:mrd) { create(:merge_request_diff) }
    let(:partitioned_mrdf) { load_partitioned_mrdf(mrd.id) }

    context 'when record is created' do
      it 'creates a new record in the partitioned table' do
        # rubocop:disable Database/MultipleDatabases -- This is a test for a partitioned table, which doesn't have an ActiveRecord model
        expect do
          mrd.tap do |diff|
            create(:merge_request_diff_file, :new_file, merge_request_diff: diff)
          end
        end.to change {
                 ActiveRecord::Base.connection.execute(
                   'SELECT COUNT(*) FROM merge_request_diff_files_99208b8fac'
                 ).first["count"]
               }.by(1)
        # rubocop:enable Database/MultipleDatabases
      end
    end

    context 'setting new_path values on create' do
      context "when original record's old_path == new_path" do
        before do
          mrd.tap do |diff|
            create(:merge_request_diff_file, :new_file, merge_request_diff: diff)
          end
        end

        it 'nullifies new_path on the partitioned record' do
          mrdf = mrd.reload.merge_request_diff_files.last

          expect(mrd.merge_request_diff_files.count).to eq(1)
          expect(mrdf.new_path).to eq(mrdf.old_path)
          expect(partitioned_mrdf.first['new_path']).to be_nil
        end
      end

      context "when original record's old_path != new_path" do
        before do
          mrd.tap do |diff|
            # Renamed files have different old_path/new_path values
            #
            create(:merge_request_diff_file, :renamed_file, merge_request_diff: diff)
          end
        end

        it 'does not nullify new_path on the partitioned record' do
          mrdf = mrd.reload.merge_request_diff_files.last

          expect(mrd.merge_request_diff_files.count).to eq(1)
          expect(mrdf.new_path).not_to eq(mrdf.old_path)
          expect(partitioned_mrdf.first['new_path']).not_to be_nil
        end
      end
    end

    context 'when record is destroyed' do
      before do
        mrd.tap do |diff|
          create(:merge_request_diff_file, :new_file, merge_request_diff: diff)
        end
      end

      it 'deletes the corresponding record in the partitioned table' do
        expect(mrd.merge_request_diff_files.count).to eq(1)

        # rubocop:disable Database/MultipleDatabases -- This is a test for a partitioned table, which doesn't have an ActiveRecord model
        expect do
          mrd.reload.merge_request_diff_files.first.destroy!
        end.to change {
                 ActiveRecord::Base.connection.execute(
                   'SELECT COUNT(*) FROM merge_request_diff_files_99208b8fac'
                 ).first["count"]
               }.by(-1)
      end
      # rubocop:enable Database/MultipleDatabases
    end

    context 'when original record is modified' do
      context "when original record is updated so that old_path != new_path" do
        before do
          mrd.tap do |diff|
            create(:merge_request_diff_file, :new_file, merge_request_diff: diff)
          end
        end

        it 'modifies the corresponding record in the partitioned table' do
          mrdf = mrd.reload.merge_request_diff_files.last

          expect(mrd.merge_request_diff_files.count).to eq(1)
          expect(mrdf.new_path).to eq(mrdf.old_path)
          expect(partitioned_mrdf.first['new_path']).to be_nil

          mrdf.update!(new_path: 'new_path')

          # Reload partitioned_mrdf result
          #
          partitioned_mrdf = load_partitioned_mrdf(mrd.id).first
          expect(mrdf.new_path).not_to eq(mrdf.old_path)
          expect(partitioned_mrdf['new_path']).to eq(mrdf.new_path)
        end
      end

      context 'when original record is updated so that old_path == new_path' do
        before do
          mrd.tap do |diff|
            # Renamed files have different old_path/new_path values
            #
            create(:merge_request_diff_file, :renamed_file, merge_request_diff: diff)
          end
        end

        it 'updates the partitioned record to nullify new_path' do
          mrdf = mrd.reload.merge_request_diff_files.last

          expect(mrd.merge_request_diff_files.count).to eq(1)
          expect(mrdf.new_path).not_to eq(mrdf.old_path)
          expect(partitioned_mrdf.first['new_path']).to eq(mrdf.new_path)

          mrdf.update!(new_path: mrdf.old_path)

          # Reload partitioned_mrdf result
          #
          partitioned_mrdf = load_partitioned_mrdf(mrd.id).first
          expect(mrdf.new_path).to eq(mrdf.old_path)
          expect(partitioned_mrdf['new_path']).to be_nil
        end
      end
    end
  end

  describe '#update_project_id callback' do
    let_it_be(:merge_request) { create(:merge_request) }

    it 'sets project_id when missing' do
      mrdf = merge_request.merge_request_diff.merge_request_diff_files.first
      mrdf.update_column(:project_id, nil)

      expect(mrdf.project_id).to be_nil

      # Normally, we would run a simple #save, then check that the validation
      #   callbacks have fired, however here I want to invoke them manually to
      #   isolate the behavior of #update_project_id
      #
      mrdf._run_validation_callbacks

      expect(mrdf.project_id).to eq(merge_request.project_id)
    end
  end

  describe '#deduplicate_new_path callback' do
    let_it_be(:merge_request) { create(:merge_request) }
    let(:mrdf) { merge_request.merge_request_diff.merge_request_diff_files.first }

    it 'does not modify new_path when it does not match old_path' do
      mrdf.update!(new_path: 'example/new_path', old_path: 'example/old_path')

      expect(mrdf[:new_path]).to eq('example/new_path')
    end

    it 'sets new_path to nil when it equals old_path' do
      mrdf.update!(new_path: 'example/path', old_path: 'example/path')

      expect(mrdf[:new_path]).to be_nil
    end

    it 'leaves new_path nil when nil' do
      mrdf.update!(new_path: nil, old_path: 'example/old_path')

      expect(mrdf[:new_path]).to be_nil
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(deduplicate_new_path_value: false)
      end

      it 'does not set new_path to nil when it equals old_path' do
        mrdf.update!(new_path: 'example/path', old_path: 'example/path')

        expect(mrdf[:new_path]).not_to be_nil
      end
    end
  end

  describe '#new_path' do
    context 'file[:new_path] exists' do
      before do
        file.update!(new_path: 'example/new_path', old_path: 'example/old_path')
      end

      it 'returns [:new_path]' do
        expect(file.new_path).to eq(file[:new_path])
      end
    end

    context 'file[:new_path] is nil' do
      before do
        file.new_path = nil
      end

      it 'returns old_path' do
        expect(file.new_path).to eq(file.old_path)
      end
    end
  end

  describe '#diff' do
    let(:file) { build(:merge_request_diff_file) }

    context 'when diff is not stored' do
      let(:unpacked) { 'unpacked' }
      let(:packed) { [unpacked].pack('m0') }

      before do
        file.diff = packed
      end

      context 'when the diff is marked as binary' do
        before do
          file.binary = true
        end

        it 'unpacks from base 64' do
          expect(file.diff).to eq(unpacked)
        end

        context 'invalid base64' do
          let(:packed) { '---/dev/null' }

          it 'returns the raw diff' do
            expect(file.diff).to eq(packed)
          end
        end
      end

      context 'when the diff is not marked as binary' do
        it 'returns the raw diff' do
          expect(file.diff).to eq(packed)
        end
      end
    end

    context 'when diff is stored in DB' do
      it 'returns UTF-8 string' do
        expect(file.diff.encoding).to eq Encoding::UTF_8
      end
    end

    context 'when diff is stored in external storage' do
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

      it 'returns UTF-8 string' do
        expect(file.diff.encoding).to eq Encoding::UTF_8
      end
    end
  end

  describe '#utf8_diff' do
    it 'does not raise error when the diff is binary' do
      file = build(:merge_request_diff_file)
      file.diff = "\x05\x00\x68\x65\x6c\x6c\x6f"

      expect { file.utf8_diff }.not_to raise_error
    end

    it 'calls #diff once' do
      allow(file).to receive(:diff).and_return('test')

      expect(file).to receive(:diff).once

      file.utf8_diff
    end

    context 'externally stored diff caching' do
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

      context 'when external diff is not cached' do
        it 'caches external diffs' do
          expect(file.merge_request_diff).to receive(:cache_external_diff).and_call_original

          expect(file.utf8_diff).to eq(file.diff)
        end
      end

      context 'when external diff is already cached' do
        it 'reads diff from cached external diff' do
          file_stub = double

          allow(file.merge_request_diff).to receive(:cached_external_diff).and_yield(file_stub)
          expect(file_stub).to receive(:seek).with(file.external_diff_offset)
          expect(file_stub).to receive(:read).with(file.external_diff_size)

          file.utf8_diff
        end
      end

      context 'when the diff is marked as binary' do
        let(:file) { build(:merge_request_diff_file) }

        before do
          allow(file.merge_request_diff).to receive(:stored_externally?).and_return(true)
          allow(file.merge_request_diff).to receive(:cached_external_diff).and_return(packed)
        end

        context 'when the diff is marked as binary' do
          before do
            file.binary = true
          end

          it 'unpacks from base 64' do
            expect(file.utf8_diff).to eq(unpacked)
          end

          context 'invalid base64' do
            let(:packed) { '---/dev/null' }

            it 'returns the raw diff' do
              expect(file.utf8_diff).to eq(packed)
            end
          end
        end

        context 'when the diff is not marked as binary' do
          it 'returns the raw diff' do
            expect(file.utf8_diff).to eq(packed)
          end
        end
      end

      context 'when content responds to #encoding' do
        it 'encodes content to utf8 encoding' do
          expect(file.utf8_diff.encoding).to eq(Encoding::UTF_8)
        end
      end

      context 'when content is blank' do
        it 'returns an empty string' do
          allow(file.merge_request_diff).to receive(:cached_external_diff).and_return(nil)

          expect(file.utf8_diff).to eq('')
        end
      end

      context 'when exception is raised' do
        it 'falls back to #diff' do
          allow(file).to receive(:binary?).and_raise(StandardError, 'Error!')
          expect(file).to receive(:diff)
          expect(Gitlab::AppLogger)
            .to receive(:warn)
            .with(
              a_hash_including(
                :message => 'Cached external diff export failed',
                :merge_request_diff_file_id => file.id,
                :merge_request_diff_id => file.merge_request_diff.id,
                'exception.class' => 'StandardError',
                'exception.message' => 'Error!'
              )
            )

          file.utf8_diff
        end
      end
    end

    context 'when diff is not stored externally' do
      it 'calls #diff' do
        expect(file).to receive(:diff)

        file.utf8_diff
      end
    end

    context 'when exception is raised' do
      it 'logs exception and returns an empty string' do
        allow(file).to receive(:diff).and_raise(StandardError, 'Error!')

        expect(Gitlab::AppLogger)
          .to receive(:warn)
          .with(
            a_hash_including(
              :message => 'Failed fetching merge request diff',
              :merge_request_diff_file_id => file.id,
              :merge_request_diff_id => file.merge_request_diff.id,
              'exception.class' => 'StandardError',
              'exception.message' => 'Error!'
            )
          )

        expect(file.utf8_diff).to eq('')
      end
    end
  end
end
