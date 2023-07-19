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

  let(:unpacked) { 'unpacked' }
  let(:packed) { [unpacked].pack('m0') }
  let(:file) { create(:merge_request).merge_request_diff.merge_request_diff_files.first }

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
