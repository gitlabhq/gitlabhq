# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::FileCollection::MergeRequestDiffBase do
  let(:merge_request) { create(:merge_request) }
  let(:diffable) { merge_request.merge_request_diff }

  describe '#overflow?' do
    subject(:overflown) { described_class.new(diffable, diff_options: nil).overflow? }

    context 'when it is not overflown' do
      it 'returns false' do
        expect(overflown).to eq(false)
      end
    end

    context 'when it is overflown' do
      before do
        diffable.update!(state: :overflow)
      end

      it 'returns true' do
        expect(overflown).to eq(true)
      end
    end
  end

  describe '#diff_files' do
    subject(:diff_files) { described_class.new(diffable, diff_options: nil).diff_files }

    it 'measures diffs_highlight_cache_decorate' do
      allow(Gitlab::Metrics).to receive(:measure).and_call_original
      expect(Gitlab::Metrics).to receive(:measure).with(:diffs_highlight_cache_decorate).and_call_original

      diff_files
    end
  end

  describe '#cache_key' do
    subject(:cache_key) { described_class.new(diffable, diff_options: nil).cache_key }

    it 'returns cache_key from merge_request_diff' do
      expect(cache_key).to eq diffable.cache_key
    end
  end

  describe '.max_blob_size' do
    let(:project) { merge_request.project }

    before do
      allow(Gitlab::Highlight).to receive(:file_size_limit).and_return(max_config)
    end

    context 'when MAX_BLOB_SIZE constant is larger' do
      let(:max_config) { described_class::MAX_BLOB_SIZE - 1 }

      it 'returns the MAX_BLOB_SIZE constant' do
        expect(described_class.max_blob_size(project)).to eq(described_class::MAX_BLOB_SIZE)
      end
    end

    context 'when maximum_text_highlight_size_kilobytes setting is larger' do
      let(:max_config) { described_class::MAX_BLOB_SIZE + 1 }

      it 'returns the maximum_text_highlight_size_kilobytes setting' do
        expect(described_class.max_blob_size(project)).to eq(max_config)
      end
    end
  end
end
