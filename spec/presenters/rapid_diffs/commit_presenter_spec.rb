# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RapidDiffs::CommitPresenter, feature_category: :source_code_management do
  let_it_be(:commit) { build_stubbed(:commit) }
  let_it_be(:project) { commit.project }
  let_it_be(:namespace) { project.namespace }
  let_it_be(:current_user) { build_stubbed(:user) }
  let(:diff_view) { :inline }
  let(:diff_options) { { ignore_whitespace_changes: true } }
  let(:diffs_count) { 20 }
  let(:base_path) { "/#{namespace.to_param}/#{project.to_param}/-/commit/#{commit.sha}" }
  let(:request_params) { {} }
  let(:resource) { commit }

  subject(:presenter) do
    described_class.new(commit, diff_view: diff_view, diff_options: diff_options,
      request_params: request_params, current_user: current_user)
  end

  before do
    allow(commit).to receive_message_chain(:diffs_for_streaming, :diff_files, :count).and_return(diffs_count)
    allow(commit).to receive(:diff_stats).and_return(nil)
  end

  describe '#diffs_slice' do
    let(:offset) { presenter.send(:offset) }

    it 'calls first_diffs_slice on the commit with the correct arguments' do
      expect(commit).to receive(:first_diffs_slice).with(offset, diff_options)

      presenter.diffs_slice
    end
  end

  it_behaves_like 'rapid diffs presenter base diffs_resource'
  it_behaves_like 'rapid diffs presenter diffs methods', sorted: false

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
        let(:diffs_count) { 2 }
        let(:diff_file) { build(:diff_file, old_path: 'old.txt', new_path: 'new.txt') }
        let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
        let(:request_params) { { old_path: 'old.txt', new_path: 'new.txt' } }

        before do
          allow(commit).to receive(:diffs).and_return(diff_files)
        end

        it { is_expected.to eq("#{base_path}/diffs_stream?skip_new_path=new.txt&skip_old_path=old.txt&view=inline") }
      end

      context 'when linked file is the only file' do
        let(:diffs_count) { 1 }
        let(:diff_file) { build(:diff_file, old_path: 'old.txt', new_path: 'new.txt') }
        let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
        let(:request_params) { { old_path: 'old.txt', new_path: 'new.txt' } }

        before do
          allow(commit).to receive(:diffs).and_return(diff_files)
        end

        it { is_expected.to be_nil }
      end

      context 'when diff_stats is available' do
        let(:stats) { instance_double(Gitlab::Git::DiffStatsCollection, count: 42) }

        before do
          allow(commit).to receive(:diff_stats).and_return(stats)
        end

        it 'uses stats count without calling diffs_for_streaming' do
          expect(commit).not_to receive(:diffs_for_streaming)

          expect(url).to eq("#{base_path}/diffs_stream?offset=5&view=inline")
        end
      end

      context 'when diff_stats returns nil' do
        before do
          allow(commit).to receive(:diff_stats).and_return(nil)
          allow(commit).to receive_message_chain(:diffs_for_streaming, :diff_files, :count).and_return(diffs_count)
        end

        it 'falls back to diffs_for_streaming' do
          expect(commit).to receive(:diffs_for_streaming)

          expect(url).to eq("#{base_path}/diffs_stream?offset=5&view=inline")
        end
      end
    end

    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url }

      it { is_expected.to eq("#{base_path}/diffs_stream") }

      context 'with skip parameters' do
        subject(:url) { presenter.reload_stream_url(skip_old_path: 'old.txt', skip_new_path: 'new.txt') }

        it { is_expected.to eq("#{base_path}/diffs_stream?skip_new_path=new.txt&skip_old_path=old.txt") }
      end
    end
  end

  describe '#discussions_endpoint' do
    subject(:url) { presenter.discussions_endpoint }

    it { is_expected.to eq("#{base_path}/discussions") }
  end

  describe '#report_abuse_path' do
    subject(:url) { presenter.report_abuse_path }

    it { is_expected.to eq("/-/abuse_reports/add_category") }
  end

  describe '#lazy?' do
    subject(:method) { presenter.lazy? }

    it { is_expected.to be(false) }
  end

  describe '#sorted?' do
    subject(:method) { presenter.sorted? }

    it { is_expected.to be(false) }
  end

  describe '#user_permissions?' do
    let(:can_create_note) { false }

    subject(:method) { presenter.user_permissions }

    before do
      allow(presenter).to receive(:can?).with(current_user, :create_note, project).and_return(can_create_note)
    end

    it { is_expected.to eq({ can_create_note: false }) }

    context 'when user has note permissions' do
      let(:can_create_note) { true }

      it { is_expected.to include({ can_create_note: true }) }
    end
  end

  describe '#noteable_type' do
    subject(:method) { presenter.noteable_type }

    it { is_expected.to eq('Commit') }
  end

  describe '#preview_markdown_endpoint' do
    subject(:method) { presenter.preview_markdown_endpoint }

    it { is_expected.to eq("/#{namespace.to_param}/#{project.to_param}/-/preview_markdown") }
  end

  describe '#markdown_docs_path' do
    subject(:method) { presenter.markdown_docs_path }

    it { is_expected.to eq('/help/user/markdown.md') }
  end

  describe '#register_path' do
    subject(:method) { presenter.register_path }

    it { is_expected.to eq('/users/sign_up?redirect_to_referer=yes') }
  end

  describe '#sign_in_path' do
    subject(:method) { presenter.sign_in_path }

    it { is_expected.to eq('/users/sign_in?redirect_to_referer=yes') }
  end

  describe '#linked_file' do
    let(:diff_file) { build(:diff_file, old_path: 'old.txt', new_path: 'new.txt') }
    let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }

    context 'when file_path is provided' do
      let(:request_params) { { file_path: 'new.txt' } }

      before do
        allow(commit).to receive(:diffs).and_return(diff_files)
      end

      it 'returns the linked file' do
        result = presenter.linked_file
        expect(result).to eq(diff_file)
        expect(result.linked).to be(true)
      end
    end

    context 'when old_path and new_path are provided' do
      let(:request_params) { { old_path: 'old.txt', new_path: 'new.txt' } }

      before do
        allow(commit).to receive(:diffs).and_return(diff_files)
      end

      it 'returns the linked file' do
        result = presenter.linked_file
        expect(result).to eq(diff_file)
        expect(result.linked).to be(true)
      end
    end

    context 'when no path parameters are provided' do
      it 'returns nil' do
        expect(presenter.linked_file).to be_nil
      end
    end
  end
end
