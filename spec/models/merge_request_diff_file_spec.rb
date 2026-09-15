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

  shared_examples 'external diff size guard' do |method_name:, storage_method:|
    before do
      allow(file.merge_request_diff).to receive(:stored_externally?).and_return(true)
    end

    context 'when too_large is already true' do
      before do
        file.too_large = true
      end

      it 'returns an empty string without reading from storage', :aggregate_failures do
        expect(file.merge_request_diff).not_to receive(storage_method)

        expect(file.public_send(method_name)).to eq('')
      end
    end
  end

  describe '#update_project_id callback' do
    let_it_be(:merge_request) { create(:merge_request) }

    it 'sets project_id from merge_request_diff' do
      merge_request_diff = merge_request.merge_request_diff

      # Build a new record in memory without saving, so project_id starts as nil
      mrdf = described_class.new(
        merge_request_diff: merge_request_diff,
        relative_order: 999,
        old_path: 'test.txt',
        new_path: 'test.txt',
        a_mode: '100644',
        b_mode: '100644',
        diff: ''
      )

      expect(mrdf.project_id).to be_nil

      # Run validation callbacks which include update_project_id
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

  describe '#too_large' do
    let(:file) { build(:merge_request_diff_file) }
    let(:current_limit) { 300.kilobytes }

    before do
      stub_application_setting(diff_max_patch_bytes: current_limit)
    end

    context 'when diff is stored externally' do
      before do
        allow(file.merge_request_diff).to receive(:stored_externally?).and_return(true)
      end

      context 'when external_diff_size is at or above diff_max_patch_bytes' do
        it 'returns true at the exact boundary' do
          file.external_diff_size = current_limit

          expect(file.too_large).to be(true)
        end

        it 'returns true above the boundary' do
          file.external_diff_size = current_limit + 1

          expect(file.too_large).to be(true)
        end
      end

      context 'when external_diff_size is below diff_max_patch_bytes' do
        before do
          file.external_diff_size = current_limit - 1
        end

        it 'returns false when the too_large column is false' do
          expect(file.too_large).to be(false)
        end

        it 'returns true when the too_large column is true' do
          file.too_large = true

          expect(file.too_large).to be(true)
        end
      end

      context 'when diff_max_patch_bytes setting is changed' do
        it 'reflects the updated setting at read time' do
          file.external_diff_size = current_limit - 1

          expect(file.too_large).to be(false)

          stub_application_setting(diff_max_patch_bytes: current_limit - 2)

          expect(file.too_large).to be(true)
        end
      end

      context 'when external_diff_size is nil' do
        before do
          file.external_diff_size = nil
        end

        it 'treats nil as 0 and falls back to the too_large column' do
          expect(file.too_large).to be(false)
        end
      end
    end

    context 'when diff is not stored externally' do
      before do
        allow(file.merge_request_diff).to receive(:stored_externally?).and_return(false)
        file.external_diff_size = current_limit
      end

      it 'does not apply the size guard and falls back to the too_large column' do
        expect(file.too_large).to be(false)
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

      it_behaves_like 'external diff size guard',
        method_name: :diff,
        storage_method: :opening_external_diff
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

      it_behaves_like 'external diff size guard',
        method_name: :utf8_diff,
        storage_method: :cached_external_diff
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
