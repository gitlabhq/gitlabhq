# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Requests Diffs' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET diffs_batch' do
    let(:headers) { {} }

    shared_examples_for 'serializes diffs with expected arguments' do
      it 'serializes paginated merge request diff collection' do
        expect_next_instance_of(PaginatedDiffSerializer) do |instance|
          expect(instance).to receive(:represent)
            .with(an_instance_of(collection), expected_options)
            .and_call_original
        end

        subject
      end
    end

    def collection_arguments(pagination_data = {})
      {
        environment: nil,
        merge_request: merge_request,
        diff_view: :inline,
        merge_ref_head_diff: nil,
        pagination_data: {
          total_pages: nil
        }.merge(pagination_data)
      }
    end

    def go(extra_params = {})
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

    context 'with caching', :use_clean_rails_memory_store_caching do
      subject { go(page: 0, per_page: 5) }

      context 'when the request has not been cached' do
        it_behaves_like 'serializes diffs with expected arguments' do
          let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
          let(:expected_options) { collection_arguments(total_pages: 20) }
        end
      end

      context 'when the request has already been cached' do
        before do
          go(page: 0, per_page: 5)
        end

        it 'does not serialize diffs' do
          expect_next_instance_of(PaginatedDiffSerializer) do |instance|
            expect(instance).not_to receive(:represent)
          end

          subject
        end

        context 'with the different pagination option' do
          subject { go(page: 5, per_page: 5) }

          it_behaves_like 'serializes diffs with expected arguments' do
            let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
            let(:expected_options) { collection_arguments(total_pages: 20) }
          end
        end

        context 'with the different diff_view' do
          subject { go(page: 0, per_page: 5, view: :parallel) }

          it_behaves_like 'serializes diffs with expected arguments' do
            let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
            let(:expected_options) { collection_arguments(total_pages: 20).merge(diff_view: :parallel) }
          end
        end

        context 'with the different expanded option' do
          subject { go(page: 0, per_page: 5, expanded: true ) }

          it_behaves_like 'serializes diffs with expected arguments' do
            let(:collection) { Gitlab::Diff::FileCollection::MergeRequestDiffBatch }
            let(:expected_options) { collection_arguments(total_pages: 20) }
          end
        end

        context 'with the different ignore_whitespace_change option' do
          subject { go(page: 0, per_page: 5, w: 1) }

          it_behaves_like 'serializes diffs with expected arguments' do
            let(:collection) { Gitlab::Diff::FileCollection::Compare }
            let(:expected_options) { collection_arguments(total_pages: 20) }
          end
        end
      end

      context 'when the paths is given' do
        subject { go(page: 0, per_page: 5, paths: %w[README CHANGELOG]) }

        it 'does not use cache' do
          expect(Rails.cache).not_to receive(:fetch).with(/cache:gitlab:PaginatedDiffSerializer/).and_call_original

          subject
        end
      end
    end
  end
end
