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
  let(:merge_request_diff) do
    instance_double(MergeRequestDiff, id: 999, merge_head?: false, diff_stats: nil, persisted?: true)
  end

  let(:resolved_diff_id) { merge_request_diff.id }
  let(:request_params) { {} }
  let(:current_user) { build_stubbed(:user) }
  let(:resource) { presenter.resource }

  subject(:presenter) do
    described_class.new(merge_request, diff_view: diff_view, diff_options: diff_options,
      request_params: request_params, current_user: current_user)
  end

  before do
    allow(merge_request).to receive_message_chain(:diffs_for_streaming, :diff_files, :count).and_return(diffs_count)
    allow(merge_request).to receive_messages(
      diff_stats: nil,
      merge_request_diff: merge_request_diff,
      diffable_merge_ref?: false,
      has_no_commits?: false
    )
    allow_any_instance_of(Gitlab::Diff::CollectionUnfolder).to receive(:unfold!) # rubocop:disable RSpec/AnyInstanceOf -- simplifies global stub
  end

  it_behaves_like 'rapid diffs presenter base diffs_resource'

  shared_examples 'calls write_cache on the collection' do
    it 'calls write_cache on the collection' do
      expect(collection).to receive(:write_cache)
      subject
    end
  end

  describe '#diffs_slice' do
    let(:offset) { presenter.send(:offset) }
    let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }
    let(:diff_collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: diff_files) }
    let(:collection) { diff_collection }

    subject { presenter.diffs_slice }

    before do
      presenter.offset = 5
      allow(diff_collection).to receive(:write_cache)
      allow(diff_files).to receive(:decorate!).and_return(diff_files)
      allow(merge_request).to receive(:first_diffs_slice).and_return(diff_collection)
    end

    it_behaves_like 'calls write_cache on the collection'

    it 'calls first_diffs_slice on the merge_request with the correct arguments' do
      expect(merge_request)
        .to receive(:first_diffs_slice)
        .with(offset, diff_options.merge(only_context_commits: false))
        .and_return(diff_collection)

      presenter.diffs_slice
    end

    context 'when only_context_commits is true' do
      let(:request_params) { { only_context_commits: 'true' } }

      it 'calls first_diffs_slice with only_context_commits: true' do
        expect(merge_request).to receive(:first_diffs_slice)
          .with(offset, diff_options.merge(only_context_commits: true))
          .and_return(diff_collection)

        presenter.diffs_slice
      end
    end

    context 'when offset is 0' do
      before do
        allow(presenter).to receive(:offset).and_return(0)
      end

      it { expect(presenter.diffs_slice).to be_nil }
    end
  end

  describe '#diff_files' do
    let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }
    let(:collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: diff_files) }

    subject { presenter.diff_files }

    before do
      allow(resource).to receive(:diffs).and_return(collection)
      allow(collection).to receive(:write_cache)
      allow(diff_files).to receive(:decorate!)
    end

    it_behaves_like 'calls write_cache on the collection'
  end

  describe '#diff_files_for_streaming' do
    let(:diff_files) { instance_double(Gitlab::Git::DiffCollection) }
    let(:collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: diff_files) }

    subject { presenter.diff_files_for_streaming }

    before do
      allow(resource).to receive(:diffs_for_streaming).and_return(collection)
      allow(collection).to receive(:write_cache)
      allow(diff_files).to receive(:decorate!)
    end

    it_behaves_like 'calls write_cache on the collection'
  end

  describe '#only_context_commits?' do
    subject(:result) { presenter.only_context_commits? }

    context 'when only_context_commits param is true' do
      let(:request_params) { { only_context_commits: 'true' } }

      it { is_expected.to be(true) }
    end

    context 'when only_context_commits param is false' do
      let(:request_params) { { only_context_commits: 'false' } }

      it { is_expected.to be(false) }
    end

    context 'when only_context_commits param is not set' do
      let(:request_params) { {} }

      it { is_expected.to be(false) }
    end

    context 'when request_params is nil' do
      subject(:result) do
        described_class.new(merge_request, diff_view: diff_view, diff_options: diff_options,
          request_params: nil).only_context_commits?
      end

      it { is_expected.to be(false) }
    end
  end

  it_behaves_like 'rapid diffs presenter diffs methods', sorted: true
  it_behaves_like 'rapid diffs presenter syntax highlighting'

  shared_examples_for 'endpoint method with diff version support' do
    context 'when diff_id is set' do
      let(:request_params) { { diff_id: 1 } }

      it { is_expected.to end_with('?diff_id=1') }

      context 'when start_sha is set' do
        let(:request_params) { { diff_id: 1, start_sha: 'abc123' } }

        it { is_expected.to end_with('?diff_id=1&start_sha=abc123') }
      end
    end

    context 'when commit_id is set' do
      let(:request_params) { { commit_id: 'abc123' } }

      it { is_expected.to end_with('?commit_id=abc123') }
    end

    context 'when resolved diff is a merge head' do
      let(:merge_request_diff) { instance_double(MergeRequestDiff, id: 999, merge_head?: true) }

      it { is_expected.not_to include('diff_id') }
    end

    context 'when resolved diff is nil' do
      let(:merge_request_diff) { nil }

      it { is_expected.not_to include('diff_id') }
    end

    context 'when only_context_commits is set' do
      let(:request_params) { { only_context_commits: 'true' } }

      it { is_expected.to end_with('only_context_commits=true') }
    end
  end

  describe '#diffs_stats_endpoint' do
    subject(:url) { presenter.diffs_stats_endpoint }

    it { is_expected.to eq("#{base_path}/diffs_stats?diff_id=#{resolved_diff_id}") }

    it_behaves_like 'endpoint method with diff version support'
  end

  describe '#diff_files_endpoint' do
    subject(:url) { presenter.diff_files_endpoint }

    it { is_expected.to eq("#{base_path}/diff_files_metadata?diff_id=#{resolved_diff_id}") }

    it_behaves_like 'endpoint method with diff version support'
  end

  describe '#diff_file_endpoint' do
    subject(:url) { presenter.diff_file_endpoint }

    it { is_expected.to eq("#{base_path}/diff_file?diff_id=#{resolved_diff_id}") }

    it_behaves_like 'endpoint method with diff version support'
  end

  describe 'stream urls' do
    describe '#diffs_stream_url' do
      subject(:url) { presenter.diffs_stream_url }

      before do
        presenter.offset = 5
      end

      it { is_expected.to eq("#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}&offset=5&view=inline") }

      context 'when diffs count is the same as streaming offset' do
        let(:diffs_count) { 5 }

        it { is_expected.to be_nil }
      end

      context 'when linked file is present and page has more diffs to stream' do
        let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
        let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
        let(:request_params) { { file_path: 'test.txt' } }

        before do
          allow(resource).to receive(:diffs).and_return(diff_files)
        end

        it 'includes diff_id and skip params' do
          expected = "#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}" \
            "&skip_new_path=test.txt&skip_old_path=test.txt&view=inline"
          is_expected.to eq(expected)
        end
      end

      context 'when linked file is the only file' do
        let(:diffs_count) { 1 }
        let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
        let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
        let(:request_params) { { file_path: 'test.txt' } }

        before do
          allow(resource).to receive(:diffs).and_return(diff_files)
        end

        it { is_expected.to be_nil }
      end

      context 'when diff_stats is available on the resolved diff' do
        let(:stats) { instance_double(Gitlab::Git::DiffStatsCollection, count: 42) }
        let(:merge_request_diff) { instance_double(MergeRequestDiff, id: 999, merge_head?: false, diff_stats: stats) }

        it 'uses stats count without calling diffs_for_streaming' do
          expect(merge_request).not_to receive(:diffs_for_streaming)

          expect(url).to eq("#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}&offset=5&view=inline")
        end
      end

      context 'when diff_stats returns nil on the resolved diff' do
        before do
          allow(merge_request).to receive_message_chain(:diffs_for_streaming, :diff_files,
            :count).and_return(diffs_count)
        end

        it 'falls back to diffs_for_streaming' do
          expect(merge_request).to receive(:diffs_for_streaming)

          expect(url).to eq("#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}&offset=5&view=inline")
        end
      end
    end

    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url }

      it { is_expected.to eq("#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}") }

      it_behaves_like 'endpoint method with diff version support'
    end
  end

  describe '#lazy?' do
    subject(:method) { presenter.lazy? }

    it { is_expected.to be(true) }

    context 'when offset is set' do
      before do
        presenter.offset = 5
      end

      it { is_expected.to be(false) }
    end
  end

  describe '#sorted?' do
    subject(:method) { presenter.sorted? }

    it { is_expected.to be(true) }
  end

  describe '#discussions_endpoint' do
    subject(:url) { presenter.discussions_endpoint }

    it { is_expected.to eq("#{base_path}/discussions") }
  end

  describe '#user_permissions' do
    let(:current_user) { build_stubbed(:user) }
    let(:can_create_note) { false }
    let(:presenter_with_user) do
      described_class.new(merge_request, diff_view: diff_view, diff_options: diff_options,
        request_params: request_params, current_user: current_user)
    end

    subject(:method) { presenter_with_user.user_permissions }

    before do
      allow(presenter_with_user).to receive(:can?).with(current_user, :create_note,
        presenter_with_user.resource).and_return(can_create_note)
    end

    it { is_expected.to include(can_create_note: false) }

    context 'when user can create notes' do
      let(:can_create_note) { true }

      it { is_expected.to include(can_create_note: true) }
    end
  end

  describe '#suggestions_help_path' do
    subject(:method) { presenter.suggestions_help_path }

    it { is_expected.to eq('/help/user/project/merge_requests/reviews/suggestions.md') }
  end

  describe '#default_suggestion_commit_message' do
    subject(:method) { presenter.default_suggestion_commit_message }

    it 'returns the default message when project has no custom message' do
      allow(project).to receive(:suggestion_commit_message).and_return(nil)
      expect(method).to eq(Gitlab::Suggestions::CommitMessage::DEFAULT_SUGGESTION_COMMIT_MESSAGE)
    end

    it 'returns the project custom message when set' do
      allow(project).to receive(:suggestion_commit_message).and_return('Custom: %{file_paths}')
      expect(method).to eq('Custom: %{file_paths}')
    end
  end

  describe '#noteable_type' do
    subject(:method) { presenter.noteable_type }

    it { is_expected.to eq('MergeRequest') }
  end

  describe '#preview_markdown_endpoint' do
    subject(:method) { presenter.preview_markdown_endpoint }

    it 'includes target_type and target_id params' do
      expected = "/#{namespace.to_param}/#{project.to_param}" \
        "/-/preview_markdown?target_id=#{merge_request.iid}&target_type=MergeRequest"
      is_expected.to eq(expected)
    end
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

  describe '#report_abuse_path' do
    subject(:method) { presenter.report_abuse_path }

    it { is_expected.to eq('/-/abuse_reports/add_category') }
  end

  describe '#new_comment_template_paths' do
    subject(:method) { presenter.new_comment_template_paths }

    it 'returns the user comment templates entry' do
      expect(method).to match_array([{ text: 'Your comment templates', href: '/-/profile/comment_templates' }])
    end
  end

  describe '#versions' do
    let(:request_params) { { diff_id: '10', start_sha: 'abc123' } }

    it 'delegates to DiffCompareVersionsEntity' do
      entity = instance_double(RapidDiffs::DiffCompareVersionsEntity)
      expect(RapidDiffs::DiffCompareVersionsEntity).to receive(:represent).with(
        resource,
        diff_id: '10',
        start_sha: 'abc123',
        commit_id: nil
      ).and_return(entity)
      expect(entity).to receive(:as_json).and_return({ 'source_versions' => [], 'target_versions' => [] })

      expect(presenter.versions).to eq({ 'source_versions' => [], 'target_versions' => [] })
    end

    context 'when commit_id is present' do
      let(:request_params) { { commit_id: 'abc123' } }

      it 'passes commit_id to the entity' do
        entity = instance_double(RapidDiffs::DiffCompareVersionsEntity)
        expect(RapidDiffs::DiffCompareVersionsEntity).to receive(:represent).with(
          resource,
          hash_including(commit_id: 'abc123')
        ).and_return(entity)
        allow(entity).to receive(:as_json).and_return({})

        presenter.versions
      end
    end

    context 'when merge request diff is not persisted' do
      let(:merge_request_diff) { instance_double(MergeRequestDiff, id: nil, persisted?: false, merge_head?: false) }

      it 'returns nil' do
        expect(presenter.versions).to be_nil
      end
    end

    context 'when merge request diff is nil' do
      let(:merge_request_diff) { nil }

      it 'returns nil' do
        expect(presenter.versions).to be_nil
      end
    end
  end

  describe 'stream urls with skip parameters' do
    describe '#reload_stream_url' do
      subject(:url) { presenter.reload_stream_url(skip_old_path: 'old.txt', skip_new_path: 'new.txt') }

      it 'includes diff_id and skip params' do
        expected = "#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}&skip_new_path=new.txt&skip_old_path=old.txt"
        is_expected.to eq(expected)
      end
    end
  end

  describe '#linked_file' do
    let(:diff_file) { build(:diff_file, old_path: 'test.txt', new_path: 'test.txt') }
    let(:diff_files) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [diff_file]) }
    let(:request_params) { { file_path: 'test.txt' } }

    before do
      allow(resource).to receive(:diffs).and_return(diff_files)
    end

    it 'returns the linked file' do
      result = presenter.linked_file
      expect(result).to eq(diff_file)
      expect(result.linked).to be(true)
    end
  end

  describe '#mr_path' do
    subject(:url) { presenter.mr_path }

    it { is_expected.to eq(base_path) }
  end

  describe '#project_path' do
    subject(:method) { presenter.project_path }

    it { is_expected.to eq(project.full_path) }
  end

  describe '#current_user' do
    let(:user) { build_stubbed(:user) }

    subject(:presenter) do
      described_class.new(merge_request, diff_view: diff_view, diff_options: diff_options,
        request_params: request_params, current_user: user)
    end

    it 'returns the current_user' do
      expect(presenter.current_user).to eq(user)
    end
  end

  describe 'diff files with conflicts' do
    let(:diff_file) { build(:diff_file) }
    let(:diff_files_array) { [diff_file] }
    let(:diff_files) do
      instance_double(Gitlab::Git::DiffCollection).tap do |collection|
        allow(collection).to receive(:decorate!) do |&block|
          diff_files_array.map!(&block)
        end
        allow(collection).to receive(:first) { diff_files_array.first }
      end
    end

    let(:diff_collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: diff_files) }
    let(:conflicts) do
      {
        diff_file.new_path => {
          conflict_type: :both_modified,
          conflict_type_when_renamed: :renamed_same_file
        }
      }
    end

    subject(:presenter) do
      described_class.new(merge_request, diff_view: diff_view, diff_options: diff_options,
        request_params: request_params, conflicts: conflicts)
    end

    before do
      allow(diff_collection).to receive(:write_cache)
      allow(resource).to receive_messages(
        diffs: diff_collection,
        first_diffs_slice: diff_collection,
        diffs_for_streaming: diff_collection
      )
    end

    describe '#diff_files' do
      it 'returns diff files wrapped in presenter with conflict info' do
        result = presenter.diff_files

        expect(result.first).to be_a(RapidDiffs::MergeRequest::DiffFilePresenter)
        expect(result.first.conflict).to eq(:both_modified)
      end

      context 'when conflicts is nil' do
        let(:conflicts) { nil }

        it 'returns diff files wrapped in presenter without conflict info' do
          result = presenter.diff_files

          expect(result.first).to be_a(RapidDiffs::MergeRequest::DiffFilePresenter)
          expect(result.first.conflict).to be_nil
        end
      end

      context 'when diff file is already wrapped in presenter' do
        let(:wrapped_file) { RapidDiffs::MergeRequest::DiffFilePresenter.new(diff_file, conflicts: conflicts) }
        let(:diff_files_array) { [wrapped_file] }

        it 'does not re-wrap the file' do
          result = presenter.diff_files

          expect(result.first).to be(wrapped_file)
        end
      end
    end

    describe '#diffs_slice' do
      before do
        presenter.offset = 5
      end

      it 'returns diff files wrapped in presenter with conflict info' do
        result = presenter.diffs_slice

        expect(result.first).to be_a(RapidDiffs::MergeRequest::DiffFilePresenter)
        expect(result.first.conflict).to eq(:both_modified)
      end
    end

    describe '#diff_files_for_streaming' do
      it 'returns diff files wrapped in presenter with conflict info' do
        result = presenter.diff_files_for_streaming

        expect(result.first).to be_a(RapidDiffs::MergeRequest::DiffFilePresenter)
        expect(result.first.conflict).to eq(:both_modified)
      end
    end

    describe '#linked_file' do
      let(:linked_file) { build(:diff_file) }
      let(:diff_files_collection) { instance_double(Gitlab::Diff::FileCollection::Base, diff_files: [linked_file]) }
      let(:conflicts) do
        {
          linked_file.file_path => {
            conflict_type: :both_modified,
            conflict_type_when_renamed: :renamed_same_file
          }
        }
      end

      let(:request_params) { { file_path: linked_file.file_path } }

      before do
        allow(resource).to receive(:diffs).and_return(diff_files_collection)
      end

      it 'returns linked file wrapped in presenter with conflict info' do
        result = presenter.linked_file

        expect(result).to be_a(RapidDiffs::MergeRequest::DiffFilePresenter)
        expect(result.conflict).to eq(:both_modified)
      end
    end

    describe '#diff_files_for_streaming_by_changed_paths' do
      before do
        allow(merge_request).to receive(:diffs_for_streaming_by_changed_paths).and_yield([diff_file])
      end

      it 'yields diff files wrapped in presenter with conflict info' do
        yielded_files = nil

        presenter.diff_files_for_streaming_by_changed_paths({}) do |files|
          yielded_files = files
        end

        expect(yielded_files.first).to be_a(RapidDiffs::MergeRequest::DiffFilePresenter)
        expect(yielded_files.first.conflict).to eq(:both_modified)
      end
    end

    describe '#reload_stream_url with context commits' do
      context 'when only_context_commits param is set' do
        let(:request_params) { { only_context_commits: 'true' } }

        it 'includes only_context_commits in the URL' do
          expect(presenter.reload_stream_url)
            .to eq("#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}&only_context_commits=true")
        end
      end

      context 'when only_context_commits param is not set' do
        let(:request_params) { {} }

        it 'does not include only_context_commits in the URL' do
          expect(presenter.reload_stream_url).to eq("#{base_path}/diffs_stream?diff_id=#{resolved_diff_id}")
        end
      end
    end
  end

  describe 'expanding context for discussions' do
    let(:diff_file) { build(:diff_file) }
    let(:diff_files_collection) do
      instance_double(Gitlab::Git::DiffCollection).tap do |collection|
        allow(collection).to receive(:decorate!).and_return(collection)
      end
    end

    let(:diff_collection) do
      instance_double(
        Gitlab::Diff::FileCollection::Base,
        diff_files: diff_files_collection,
        diff_file_paths: [diff_file.new_path]
      )
    end

    let(:unfolder) { instance_double(Gitlab::Diff::CollectionUnfolder) }

    before do
      allow(Gitlab::Diff::CollectionUnfolder).to receive(:new)
        .with(resource, current_user).and_return(unfolder)
      allow(diff_collection).to receive(:write_cache)
      allow(unfolder).to receive(:unfold!)
      allow(resource).to receive_messages(
        diffs: diff_collection,
        first_diffs_slice: diff_collection,
        diffs_for_streaming: diff_collection
      )
    end

    it 'unfolds diff_files collection' do
      expect(unfolder).to receive(:unfold!).with(diff_collection)

      presenter.diff_files
    end

    it 'unfolds diffs_slice collection' do
      presenter.offset = 5
      expect(unfolder).to receive(:unfold!).with(diff_collection)

      presenter.diffs_slice
    end

    it 'unfolds diff_files_for_streaming collection' do
      expect(unfolder).to receive(:unfold!).with(diff_collection)

      presenter.diff_files_for_streaming
    end
  end
end
