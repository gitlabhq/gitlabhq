# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Delete an upload', feature_category: :navigation do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: group) }

  let(:extra_params) { {} }
  let(:params) { { filename: File.basename(upload.path), secret: upload.secret }.merge(extra_params) }
  let(:mutation) { graphql_mutation(:uploadDelete, params) }
  let(:mutation_response) { graphql_mutation_response(:upload_delete) }

  shared_examples_for 'upload deletion' do
    context 'when the user is not allowed to delete uploads' do
      let(:current_user) { developer }

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when the user is anonymous' do
      let(:current_user) { nil }

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when user has permissions to delete uploads' do
      let(:current_user) { maintainer }

      it 'deletes the upload' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['upload']).to include('id' => upload.to_global_id.to_s)
        expect(mutation_response['errors']).to be_empty
      end

      context 'when upload does not exist' do
        let(:params) { { filename: 'invalid', secret: upload.secret }.merge(extra_params) }

        it 'returns an error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(response).to have_gitlab_http_status(:success)
          expect(mutation_response['upload']).to be_nil
          expect(mutation_response['errors']).to match_array(
            [
              "The resource that you are attempting to access does not "\
              "exist or you don't have permission to perform this action."
            ])
        end
      end
    end
  end

  context 'when deleting project upload' do
    let_it_be_with_reload(:upload) { create(:upload, :issuable_upload, model: project) }

    let(:extra_params) { { project_path: project.full_path } }

    it_behaves_like 'upload deletion'
  end

  context 'when deleting group upload' do
    let_it_be_with_reload(:upload) { create(:upload, :namespace_upload, model: group) }

    let(:extra_params) { { group_path: group.full_path } }

    it_behaves_like 'upload deletion'
  end
end
