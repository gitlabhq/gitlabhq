# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RapidDiffs::CommitPresenter, feature_category: :source_code_management do
  let_it_be(:commit) { build_stubbed(:commit) }
  let_it_be(:project) { commit.project }
  let_it_be(:namespace) { project.namespace }
  let(:diff_view) { :inline }
  let(:diff_options) { { ignore_whitespace_changes: true } }
  let(:diffs_count) { 20 }
  let(:base_path) { "/#{namespace.to_param}/#{project.to_param}/-/commit/#{commit.sha}" }

  subject(:presenter) { described_class.new(commit, diff_view, diff_options) }

  before do
    allow(commit).to receive_message_chain(:diffs_for_streaming, :diff_files, :count).and_return(diffs_count)
  end

  describe '#diffs_slice' do
    let(:offset) { presenter.send(:offset) }

    it 'calls first_diffs_slice on the commit with the correct arguments' do
      expect(commit).to receive(:first_diffs_slice).with(offset, diff_options)

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

  describe '#discussions_endpoint' do
    subject(:url) { presenter.discussions_endpoint }

    it { is_expected.to eq("#{base_path}/discussions") }
  end

  describe '#lazy?' do
    subject(:method) { presenter.lazy? }

    it { is_expected.to be(false) }
  end

  describe '#should_sort_metadata_files?' do
    subject(:method) { presenter.should_sort_metadata_files? }

    it { is_expected.to be(false) }
  end
end
