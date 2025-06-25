# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RapidDiffs::ComparePresenter, feature_category: :source_code_management do
  let_it_be(:project) { build_stubbed(:project) }
  let(:compare) { instance_double(Compare, project: project) }
  let(:namespace) { project.namespace }
  let(:diff_view) { :inline }
  let(:diff_options) { { ignore_whitespace_changes: true } }
  let(:request_params) { { from: 'a', to: 'b' } }
  let(:base_path) { "/#{namespace.to_param}/#{project.to_param}/-/compare" }
  let(:url_params) { '?from=a&to=b' }

  subject(:presenter) { described_class.new(compare, diff_view, diff_options, request_params) }

  describe '#diffs_slice' do
    subject(:diffs_slice) { presenter.diffs_slice }

    it { is_expected.to be_nil }
  end

  describe '#diffs_stats_endpoint' do
    subject(:url) { presenter.diffs_stats_endpoint }

    it { is_expected.to eq("#{base_path}/diffs_stats#{url_params}") }
  end

  describe '#diff_files_endpoint' do
    subject(:url) { presenter.diff_files_endpoint }

    it { is_expected.to eq("#{base_path}/diff_files_metadata#{url_params}") }
  end

  describe '#diff_file_endpoint' do
    subject(:url) { presenter.diff_file_endpoint }

    it { is_expected.to eq("#{base_path}/diff_file#{url_params}") }
  end

  describe 'stream urls' do
    describe '#diffs_stream_url' do
      subject(:url) { presenter.diffs_stream_url }

      it { is_expected.to be_nil }
    end

    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url }

      it { is_expected.to eq("#{base_path}/diffs_stream#{url_params}") }
    end
  end

  describe '#lazy?' do
    subject(:method) { presenter.lazy? }

    it { is_expected.to be(true) }
  end

  describe '#should_sort_metadata_files?' do
    subject(:method) { presenter.should_sort_metadata_files? }

    it { is_expected.to be(false) }
  end

  # this method is tested only because code coverage can not detect its usage because of overrides
  describe '#offset' do
    subject(:method) { presenter.send(:offset) }

    it { is_expected.to be_nil }
  end
end
