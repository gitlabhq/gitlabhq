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

  subject(:presenter) { described_class.new(merge_request, diff_view, diff_options) }

  before do
    allow(merge_request).to receive_message_chain(:diffs_for_streaming, :diff_files, :count).and_return(diffs_count)
  end

  describe '#diffs_slice' do
    let(:offset) { presenter.send(:offset) }

    it 'calls first_diffs_slice on the merge_request with the correct arguments' do
      expect(merge_request).to receive(:first_diffs_slice).with(offset, diff_options)

      presenter.diffs_slice
    end
  end

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

  describe '#should_sort_metadata_files?' do
    subject(:method) { presenter.should_sort_metadata_files? }

    it { is_expected.to be(true) }
  end
end
