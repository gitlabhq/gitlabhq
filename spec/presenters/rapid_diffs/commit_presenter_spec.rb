# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::RapidDiffs::CommitPresenter, feature_category: :source_code_management do
  let_it_be_with_reload(:commit) { build_stubbed(:commit) }
  let_it_be(:project) { commit.project }
  let_it_be(:namespace) { project.namespace }
  let_it_be(:current_user) { build_stubbed(:user) }
  let(:diff_view) { :inline }
  let(:diff_options) { { ignore_whitespace_changes: true } }
  let(:base_path) { "/#{namespace.to_param}/#{project.to_param}/-/commit/#{commit.sha}" }
  let(:request_params) { {} }
  let(:resource) { commit }

  subject(:presenter) do
    described_class.new(commit, diff_view: diff_view, diff_options: diff_options,
      request_params: request_params, current_user: current_user)
  end

  before do
    allow(commit).to receive(:diff_stats).and_return(nil)
  end

  def stub_first_diffs_slice(count:, overflow: false)
    slice = instance_double(Gitlab::Git::DiffCollection)
    allow(slice).to receive_messages(decorate!: slice, first: [])
    instance_double(Gitlab::Diff::FileCollection::Base, count: count, overflow?: overflow, diff_files: slice)
  end

  describe '#diffs_slice' do
    let(:offset) { presenter.send(:offset) }
    let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }
    let(:diff_collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: diff_files) }
    let(:expected_diff_options) { diff_options.merge(include_stats: false) }

    it 'calls first_diffs_slice on the commit with the correct arguments' do
      allow(diff_files).to receive(:decorate!).and_return(diff_files)
      allow(diff_files).to receive(:first).with(offset).and_return([])
      expect(commit).to receive(:first_diffs_slice).with(offset, expected_diff_options).and_return(diff_collection)

      presenter.diffs_slice
    end
  end

  it_behaves_like 'rapid diffs presenter base diffs_resource'
  it_behaves_like 'rapid diffs presenter diffs methods', sorted: false
  it_behaves_like 'rapid diffs presenter syntax highlighting'
  it_behaves_like 'rapid diffs presenter overflow detection'

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

      before do
        allow(commit).to receive(:first_diffs_slice).and_return(stub_first_diffs_slice(count: 5, overflow: true))
      end

      it { is_expected.to eq("#{base_path}/diffs_stream?offset=5&view=inline") }

      context 'when there is no overflow' do
        before do
          allow(commit).to receive(:first_diffs_slice).and_return(stub_first_diffs_slice(count: 5))
        end

        it { is_expected.to be_nil }
      end

      context 'when the slice overflowed before reaching the offset' do
        before do
          allow(commit).to receive(:first_diffs_slice).and_return(stub_first_diffs_slice(count: 2, overflow: true))
        end

        it 'streams from the number of files that were actually loaded' do
          is_expected.to eq("#{base_path}/diffs_stream?offset=2&view=inline")
        end
      end

      context 'when linked file is present and page has more diffs to stream' do
        let(:diff_file) { build(:diff_file, old_path: 'old.txt', new_path: 'new.txt') }
        let(:diff_files) do
          raw = instance_double(Gitlab::Git::DiffCollection)
          allow(raw).to receive_messages(first: diff_file, decorate!: raw)
          instance_double(Gitlab::Diff::FileCollection::Base, diff_files: raw)
        end

        let(:request_params) { { old_path: 'old.txt', new_path: 'new.txt' } }

        before do
          allow(commit).to receive_messages(
            diffs: diff_files,
            first_diffs_slice: stub_first_diffs_slice(count: 2, overflow: true)
          )
        end

        it { is_expected.to eq("#{base_path}/diffs_stream?skip_new_path=new.txt&skip_old_path=old.txt&view=inline") }
      end

      context 'when linked file is the only file' do
        let(:diff_file) { build(:diff_file, old_path: 'old.txt', new_path: 'new.txt') }
        let(:diff_files) do
          raw = instance_double(Gitlab::Git::DiffCollection)
          allow(raw).to receive_messages(first: diff_file, decorate!: raw)
          instance_double(Gitlab::Diff::FileCollection::Base, diff_files: raw)
        end

        let(:request_params) { { old_path: 'old.txt', new_path: 'new.txt' } }

        before do
          allow(commit).to receive_messages(
            diffs: diff_files,
            first_diffs_slice: stub_first_diffs_slice(count: 1)
          )
        end

        it { is_expected.to be_nil }
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

  describe '#empty_state_type' do
    subject(:type) { presenter.empty_state_type }

    context 'when the loaded slice is empty' do
      before do
        allow(commit).to receive(:first_diffs_slice).and_return(stub_first_diffs_slice(count: 0))
      end

      it { is_expected.to eq(:no_changes) }

      it 'does not request the diffs for streaming' do
        expect(commit).not_to receive(:diffs_for_streaming)

        expect(type).to eq(:no_changes)
      end
    end

    context 'when the loaded slice has files' do
      before do
        allow(commit).to receive(:first_diffs_slice).and_return(stub_first_diffs_slice(count: 3))
      end

      it { is_expected.to be_nil }
    end
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
    let(:diff_files) do
      raw = instance_double(Gitlab::Git::DiffCollection)
      allow(raw).to receive_messages(first: diff_file, decorate!: raw)
      instance_double(Gitlab::Diff::FileCollection::Base, diff_files: raw)
    end

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
