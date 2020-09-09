# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestDiffFile do
  it_behaves_like 'a BulkInsertSafe model', MergeRequestDiffFile do
    let(:valid_items_for_bulk_insertion) do
      build_list(:merge_request_diff_file, 10) do |mr_diff_file|
        mr_diff_file.merge_request_diff = create(:merge_request_diff)
      end
    end

    let(:invalid_items_for_bulk_insertion) { [] } # class does not have any validations defined
  end

  describe '#diff' do
    context 'when diff is not stored' do
      let(:unpacked) { 'unpacked' }
      let(:packed) { [unpacked].pack('m0') }

      before do
        subject.diff = packed
      end

      context 'when the diff is marked as binary' do
        before do
          subject.binary = true
        end

        it 'unpacks from base 64' do
          expect(subject.diff).to eq(unpacked)
        end

        context 'invalid base64' do
          let(:packed) { '---/dev/null' }

          it 'returns the raw diff' do
            expect(subject.diff).to eq(packed)
          end
        end
      end

      context 'when the diff is not marked as binary' do
        it 'returns the raw diff' do
          expect(subject.diff).to eq(packed)
        end
      end
    end

    context 'when diff is stored in DB' do
      let(:file) { create(:merge_request).merge_request_diff.merge_request_diff_files.first }

      it 'returns UTF-8 string' do
        expect(file.diff.encoding).to eq Encoding::UTF_8
      end
    end

    context 'when diff is stored in external storage' do
      let(:file) { create(:merge_request).merge_request_diff.merge_request_diff_files.first }
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
      subject.diff = "\x05\x00\x68\x65\x6c\x6c\x6f"

      expect { subject.utf8_diff }.not_to raise_error
    end
  end
end
