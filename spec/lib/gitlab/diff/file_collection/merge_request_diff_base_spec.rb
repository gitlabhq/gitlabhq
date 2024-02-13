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

    context 'when increase_diff_file_performance is enabled' do
      before do
        allow(Gitlab::Git::Diff).to receive(:patch_hard_limit_bytes).and_return(max_diff)
        stub_config(extra: { 'maximum_text_highlight_size_kilobytes' => max_config })
      end

      context 'when Gitlab::Git::Diff.patch_hard_limit_bytes is larger' do
        let(:max_diff) { 10 }
        let(:max_config) { 1 }

        it 'returns the Gitlab::Git::Diff.patch_hard_limit_bytes setting' do
          expect(described_class.max_blob_size(project)).to eq(max_diff)
        end
      end

      context 'when maximum_text_highlight_size_kilobytes setting is larger' do
        let(:max_diff) { 10 }
        let(:max_config) { 100 }

        it 'returns the maximum_text_highlight_size_kilobytes setting' do
          expect(described_class.max_blob_size(project)).to eq(max_config)
        end
      end
    end

    context 'when increase_diff_file_performance is disabled' do
      before do
        stub_feature_flags(increase_diff_file_performance: false)
      end

      it 'returns nil' do
        expect(described_class.max_blob_size(project)).to eq(nil)
      end
    end
  end
end
