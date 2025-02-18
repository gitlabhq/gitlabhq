# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Diffs', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET diffs_batch' do
    shared_examples_for 'serializes diffs with expected arguments' do
      it 'serializes paginated merge request diff collection' do
        expect_next_instance_of(PaginatedDiffSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(collection), expected_options)
            .and_call_original
        end

        subject

        expect(response).to have_gitlab_http_status(:success)
      end
    end

    def collection_arguments(pagination_data = {})
      {
        merge_request: merge_request,
        commit: nil,
        diff_view: :inline,
        merge_ref_head_diff: nil,
        pagination_data: {
          total_pages: nil
        }.merge(pagination_data)
      }
    end

    def go(headers: {}, **extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid,
        page: 0,
        per_page: 20,
        format: 'json'
      }

      get diffs_batch_namespace_project_json_merge_request_path(params.merge(extra_params)), headers: headers
    end

    context 'without caching' do
      subject { go(headers: headers, page: 0, per_page: 5) }

      let(:headers) { {} }
      let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
      let(:expected_options) { collection_arguments(total_pages: 20) }

      it_behaves_like 'serializes diffs with expected arguments'

      context 'with externally stored diff' do
        let(:branch_name) { "test-diff-branch-#{SecureRandom.hex}" }
        let(:merge_request) do
          create(:merge_request, target_project: project, source_project: project, source_branch: branch_name)
        end

        let(:expected_options) { collection_arguments(total_pages: 2) }

        before do
          stub_object_storage_uploader(
            config: Gitlab.config.external_diffs.object_store,
            uploader: ExternalDiffUploader,
            direct_upload: true
          )

          stub_external_diffs_setting(enabled: true)

          project.repository.commit_files(
            user,
            branch_name: branch_name,
            message: 'some text file',
            actions: [{
              action: :create,
              file_path: "#{branch_name}.txt",
              content: 'some stuff'
            }]
          )

          project.repository.commit_files(
            user,
            branch_name: branch_name,
            message: 'empty file',
            actions: [{
              action: :create,
              file_path: "empty-#{branch_name}.txt",
              content: nil
            }]
          )

          # HttpIO will make a direct call to the URL, so stub that request with the actual diff
          stub_request(:get, /merge_request_diffs/)
            .to_return(status: 200, body: merge_request.merge_request_diff.external_diff.file.read, headers: {})
        end

        it_behaves_like 'serializes diffs with expected arguments'
      end
    end

    context 'with caching', :use_clean_rails_memory_store_caching do
      subject { go(headers: headers, page: 0, per_page: 5) }

      let(:headers) { { 'If-None-Match' => response.etag } }

      before do
        go(page: 0, per_page: 5)
      end

      it 'does not serialize diffs' do
        expect(PaginatedDiffSerializer).not_to receive(:new)

        go(headers: headers, page: 0, per_page: 5)

        expect(response).to have_gitlab_http_status(:not_modified)
      end

      context 'with the different user' do
        let(:another_user) { create(:user) }
        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20) }

        before do
          project.add_maintainer(another_user)
          sign_in(another_user)
        end

        it_behaves_like 'serializes diffs with expected arguments'
      end

      context 'with a new unfoldable diff position' do
        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20) }

        let(:unfoldable_position) do
          create(:diff_position)
        end

        before do
          expect_next_instance_of(Gitlab::Diff::PositionCollection) do |instance|
            expect(instance)
              .to receive(:unfoldable)
              .and_return([unfoldable_position])
          end
        end

        it_behaves_like 'serializes diffs with expected arguments'
      end

      context 'with diff_head option' do
        subject { go(page: 0, per_page: 5, diff_head: true) }

        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20).merge(merge_ref_head_diff: true) }

        before do
          merge_request.create_merge_head_diff!
        end

        it_behaves_like 'serializes diffs with expected arguments'
      end

      context 'with the different pagination option' do
        subject { go(page: 5, per_page: 5) }

        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20) }

        it_behaves_like 'serializes diffs with expected arguments'
      end

      context 'with the different diff_view' do
        subject { go(page: 0, per_page: 5, view: :parallel) }

        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20).merge(diff_view: :parallel) }

        it_behaves_like 'serializes diffs with expected arguments'
      end

      context 'with the different expanded option' do
        subject { go(page: 0, per_page: 5, expanded: true) }

        let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
        let(:expected_options) { collection_arguments(total_pages: 20) }

        it_behaves_like 'serializes diffs with expected arguments'
      end

      context 'with the different ignore_whitespace_change option' do
        subject { go(page: 0, per_page: 5, w: 1) }

        let(:collection) { Gitlab::Diff::FileCollection::Compare }
        let(:expected_options) { collection_arguments(total_pages: 20) }

        it_behaves_like 'serializes diffs with expected arguments'
      end
    end

    context 'when the paths is given' do
      subject { go(headers: headers, page: 0, per_page: 5, paths: %w[README CHANGELOG]) }

      before do
        go(page: 0, per_page: 5, paths: %w[README CHANGELOG])
      end

      context 'when using ETag caching' do
        let(:headers) { { 'If-None-Match' => response.etag } }

        it 'does not serialize diffs' do
          expect(PaginatedDiffSerializer).not_to receive(:new)

          subject

          expect(response).to have_gitlab_http_status(:not_modified)
        end
      end

      context 'when not using ETag caching' do
        let(:headers) { {} }

        it 'does not use cache' do
          expect(Rails.cache).not_to receive(:fetch).with(/cache:gitlab:PaginatedDiffSerializer/).and_call_original

          subject

          expect(response).to have_gitlab_http_status(:success)
        end
      end
    end
  end
end
