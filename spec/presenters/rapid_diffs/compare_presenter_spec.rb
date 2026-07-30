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
  let(:current_user) { build_stubbed(:user) }
  let(:resource) { compare }

  subject(:presenter) do
    described_class.new(compare, diff_view: diff_view, diff_options: diff_options, request_params: request_params,
      current_user: current_user)
  end

  def stub_first_diffs_slice(count:, overflow: false)
    slice = instance_double(Gitlab::Git::DiffCollection)
    allow(slice).to receive_messages(decorate!: slice, first: [])
    instance_double(Gitlab::Diff::FileCollection::Base, count: count, overflow?: overflow, diff_files: slice)
  end

  describe '#diffs_slice' do
    subject(:diffs_slice) { presenter.diffs_slice }

    it { is_expected.to be_nil }
  end

  it_behaves_like 'rapid diffs presenter base diffs_resource'
  it_behaves_like 'rapid diffs presenter diffs methods', sorted: false
  it_behaves_like 'rapid diffs presenter syntax highlighting'

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

      it { is_expected.to eq("#{base_path}/diffs_stream#{url_params}&view=#{diff_view}") }

      context 'when linked file is present and page has more diffs to stream' do
        let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
        let(:diff_files) do
          raw = instance_double(Gitlab::Git::DiffCollection)
          allow(raw).to receive_messages(first: diff_file, decorate!: raw)
          instance_double(Gitlab::Diff::FileCollection::Base, diff_files: raw)
        end

        let(:request_params) { { from: 'a', to: 'b', file_path: 'test.txt' } }

        before do
          allow(compare).to receive_messages(
            diffs: diff_files,
            first_diffs_slice: stub_first_diffs_slice(count: 2, overflow: true)
          )
        end

        it 'includes skip parameters' do
          expect(url).to include('skip_new_path=test.txt')
          expect(url).to include('skip_old_path=test.txt')
          expect(url).to include('from=a')
          expect(url).to include('to=b')
        end
      end

      context 'when linked file is the only file' do
        let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
        let(:diff_files) do
          raw = instance_double(Gitlab::Git::DiffCollection)
          allow(raw).to receive_messages(first: diff_file, decorate!: raw)
          instance_double(Gitlab::Diff::FileCollection::Base, diff_files: raw)
        end

        let(:request_params) { { from: 'a', to: 'b', file_path: 'test.txt' } }

        before do
          allow(compare).to receive_messages(
            diffs: diff_files,
            first_diffs_slice: stub_first_diffs_slice(count: 1)
          )
        end

        it { is_expected.to be_nil }
      end
    end

    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url }

      it { is_expected.to eq("#{base_path}/diffs_stream#{url_params}") }

      context 'with skip parameters' do
        subject(:url) { presenter.reload_stream_url(skip_old_path: 'old.txt', skip_new_path: 'new.txt') }

        it 'includes skip parameters' do
          expect(url).to include('skip_new_path=new.txt')
          expect(url).to include('skip_old_path=old.txt')
          expect(url).to include('from=a')
          expect(url).to include('to=b')
        end
      end
    end
  end

  describe '#lazy?' do
    subject(:method) { presenter.lazy? }

    it { is_expected.to be(false) }
  end

  describe '#sorted?' do
    subject(:method) { presenter.sorted? }

    it { is_expected.to be(false) }
  end

  # this method is tested only because code coverage can not detect its usage because of overrides
  describe '#offset' do
    subject(:method) { presenter.send(:offset) }

    it { is_expected.to eq(0) }
  end

  describe '#linked_file' do
    let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
    let(:diff_files) do
      raw = instance_double(Gitlab::Git::DiffCollection)
      allow(raw).to receive_messages(first: diff_file, decorate!: raw)
      instance_double(Gitlab::Diff::FileCollection::Base, diff_files: raw)
    end

    let(:request_params) { { from: 'a', to: 'b', file_path: 'test.txt' } }

    before do
      allow(compare).to receive(:diffs).and_return(diff_files)
    end

    it 'returns the linked file' do
      result = presenter.linked_file
      expect(result).to eq(diff_file)
      expect(result.linked).to be(true)
    end
  end
end
