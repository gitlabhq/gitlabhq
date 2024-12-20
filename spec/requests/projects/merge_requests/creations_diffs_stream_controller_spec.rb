# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge Request Creations diffs stream', feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user, maintainer_of: project) }
  let_it_be(:source_branch) { 'fix' }
  let_it_be(:target_branch) { 'master' }

  let_it_be(:compare) do
    CompareService.new(
      project,
      source_branch
    ).execute(
      project,
      target_branch
    )
  end

  let_it_be(:offset) { 0 }
  let_it_be(:diff_files) { compare.diffs.diff_files }

  before do
    sign_in(user)
  end

  describe 'GET diffs_stream' do
    def go(**extra_params)
      params = {
        namespace_id: project.namespace,
        project_id: project,
        offset: offset,
        merge_request: {
          source_branch: source_branch,
          target_branch: target_branch
        }
      }

      get namespace_project_new_merge_request_diffs_stream_path(params.merge(extra_params))
    end

    it 'includes all diffs' do
      go

      streamed_content = response.body

      diff_files.each do |diff_file|
        expect(streamed_content).to include(diff_file.new_path)
      end
    end

    include_examples 'diffs stream tests'

    context 'when user does not access to create merge request' do
      let(:user) { create(:user) }

      it 'returns a 404 status' do
        go

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when merge request cannot be created' do
      before do
        allow_next_instance_of(MergeRequest) do |instance|
          allow(instance).to receive(:can_be_created).and_return(false)
        end
      end

      it 'no diffs are streamed' do
        go

        expect(response.body).to be_empty
      end
    end
  end
end
