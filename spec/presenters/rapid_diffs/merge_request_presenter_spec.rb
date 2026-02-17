# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RapidDiffs::MergeRequestPresenter, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { build_stubbed(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:namespace) { project.namespace }
  let(:diff_view) { :inline }
  let(:diff_options) { { ignore_whitespace_changes: true } }
  let(:diffs_count) { 20 }
  let(:base_path) { "/#{namespace.to_param}/#{project.to_param}/-/merge_requests/#{merge_request.to_param}" }
  let(:request_params) { {} }
  let(:resource) { merge_request }

  subject(:presenter) do
    described_class.new(merge_request, diff_view: diff_view, diff_options: diff_options,
      request_params: request_params)
  end

  before do
    allow(merge_request).to receive_message_chain(:diffs_for_streaming, :diff_files, :count).and_return(diffs_count)
    allow(merge_request).to receive(:diff_stats).and_return(nil)
  end

  describe '#diffs_resource' do
    it 'calls latest_diffs on the merge_request with merged options' do
      extra_options = { expand_all: true }

      expect(merge_request).to receive(:latest_diffs).with(diff_options.merge(extra_options))

      presenter.diffs_resource(extra_options)
    end
  end

  describe '#diffs_slice' do
    let(:offset) { presenter.send(:offset) }

    it 'calls first_diffs_slice on the merge_request with the correct arguments' do
      expect(merge_request).to receive(:first_diffs_slice).with(offset, diff_options)

      presenter.diffs_slice
    end
  end

  it_behaves_like 'rapid diffs presenter diffs methods', sorted: true

  describe '#diffs_stats_endpoint' do
    subject(:url) { presenter.diffs_stats_endpoint }

    it { is_expected.to eq("#{base_path}/diffs_stats") }
  end

  describe '#diff_files_endpoint' do
    subject(:url) { presenter.diff_files_endpoint }

    it { is_expected.to eq("#{base_path}/diff_files_metadata") }
  end

  describe '#diff_file_endpoint' do
    subject(:url) { presenter.diff_file_endpoint }

    it { is_expected.to eq("#{base_path}/diff_file") }
  end

  describe 'stream urls' do
    describe '#diffs_stream_url' do
      subject(:url) { presenter.diffs_stream_url }

      it { is_expected.to eq("#{base_path}/diffs_stream?offset=5&view=inline") }

      context 'when diffs count is the same as streaming offset' do
        let(:diffs_count) { 5 }

        it { is_expected.to be_nil }
      end

      context 'when linked file is present and page has more diffs to stream' do
        let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
        let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
        let(:request_params) { { file_path: 'test.txt' } }

        before do
          allow(merge_request).to receive(:diffs).and_return(diff_files)
        end

        it { is_expected.to eq("#{base_path}/diffs_stream?skip_new_path=test.txt&skip_old_path=test.txt&view=inline") }
      end

      context 'when linked file is the only file' do
        let(:diffs_count) { 1 }
        let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
        let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
        let(:request_params) { { file_path: 'test.txt' } }

        before do
          allow(merge_request).to receive(:diffs).and_return(diff_files)
        end

        it { is_expected.to be_nil }
      end

      context 'when diff_stats is available' do
        let(:stats) { instance_double(Gitlab::Git::DiffStatsCollection, count: 42) }

        before do
          allow(merge_request).to receive(:diff_stats).and_return(stats)
        end

        it 'uses stats count without calling diffs_for_streaming' do
          expect(merge_request).not_to receive(:diffs_for_streaming)

          expect(url).to eq("#{base_path}/diffs_stream?offset=5&view=inline")
        end
      end

      context 'when diff_stats returns nil' do
        before do
          allow(merge_request).to receive(:diff_stats).and_return(nil)
          allow(merge_request).to receive_message_chain(:diffs_for_streaming, :diff_files,
            :count).and_return(diffs_count)
        end

        it 'falls back to diffs_for_streaming' do
          expect(merge_request).to receive(:diffs_for_streaming)

          expect(url).to eq("#{base_path}/diffs_stream?offset=5&view=inline")
        end
      end
    end

    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url }

      it { is_expected.to eq("#{base_path}/diffs_stream") }
    end
  end

  describe '#lazy?' do
    subject(:method) { presenter.lazy? }

    it { is_expected.to be(false) }
  end

  describe '#sorted?' do
    subject(:method) { presenter.sorted? }

    it { is_expected.to be(true) }
  end

  describe 'stream urls with skip parameters' do
    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url(skip_old_path: 'old.txt', skip_new_path: 'new.txt') }

      it { is_expected.to eq("#{base_path}/diffs_stream?skip_new_path=new.txt&skip_old_path=old.txt") }
    end
  end

  describe '#linked_file' do
    let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
    let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
    let(:request_params) { { file_path: 'test.txt' } }

    before do
      allow(merge_request).to receive(:diffs).and_return(diff_files)
    end

    it 'returns the linked file' do
      result = presenter.linked_file
      expect(result).to eq(diff_file)
      expect(result.linked).to be(true)
    end
  end
end
