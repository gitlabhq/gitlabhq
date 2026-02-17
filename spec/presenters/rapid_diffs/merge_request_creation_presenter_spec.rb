# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RapidDiffs::MergeRequestCreationPresenter, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { build_stubbed(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:namespace) { project.namespace }
  let(:diff_view) { :inline }
  let(:diff_options) { { ignore_whitespace_changes: true } }
  let(:request_params) { { source_branch: 'a', target_branch: 'b' } }
  let(:base_path) { "/#{namespace.to_param}/#{project.to_param}/-/merge_requests/new" }
  let(:url_params) { '?source_branch=a&target_branch=b' }
  let(:resource) { merge_request }

  subject(:presenter) do
    described_class.new(merge_request, project: project, diff_view: diff_view, diff_options: diff_options,
      request_params: request_params)
  end

  describe '#diffs_slice' do
    subject(:diffs_slice) { presenter.diffs_slice }

    it { is_expected.to be_nil }
  end

  it_behaves_like 'rapid diffs presenter base diffs_resource'
  it_behaves_like 'rapid diffs presenter diffs methods', sorted: false

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

  describe '#sorted?' do
    subject(:method) { presenter.sorted? }

    it { is_expected.to be(false) }
  end

  # this method is tested only because code coverage can not detect its usage because of overrides
  describe '#offset' do
    subject(:method) { presenter.send(:offset) }

    it { is_expected.to be_nil }
  end

  describe '#linked_file' do
    let(:request_params) { { source_branch: 'a', target_branch: 'b', old_path: 'test.txt', new_path: 'test.txt' } }

    it 'returns nil because presenter is lazy' do
      expect(presenter.linked_file).to be_nil
    end
  end
end
