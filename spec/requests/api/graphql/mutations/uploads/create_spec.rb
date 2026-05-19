# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an upload', feature_category: :team_planning do
  include GraphqlHelpers
  include WorkhorseHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }

  let(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }
  let(:extra_params) { {} }
  let(:params) { { file: file }.merge(extra_params) }
  let(:mutation_response) { graphql_mutation_response(:upload_create) }

  def mutation
    graphql_mutation(:uploadCreate, params)
  end

  shared_examples_for 'upload creation' do
    context 'when the user is not allowed to create uploads' do
      let(:current_user) { create(:user) }

      it 'returns an error' do
        post_graphql_mutation_with_uploads(mutation, current_user: current_user)

        expect(graphql_errors).to be_present
      end
    end

    context 'when user has permissions to create uploads' do
      let(:current_user) { guest }

      it 'creates the upload' do
        expect { post_graphql_mutation_with_uploads(mutation, current_user: current_user) }
          .to change { Upload.count }.by(1)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_blank
        expect(mutation_response['upload']).to include('id' => Upload.last.to_global_id.to_s)
        expect(mutation_response['markdown']).to match(%r{!\[dk\]\(/uploads/\h{32}/dk\.png\)})
        expect(mutation_response['url']).to match(%r{/uploads/\h{32}/dk\.png})
        expect(mutation_response['alt']).to eq('dk')
        expect(mutation_response['fullPath']).to match(%r{/-/\w+/\d+/uploads/\h{32}/dk\.png})
        expect(mutation_response['errors']).to be_empty
      end

      context 'when the upload service fails' do
        let(:current_user) { guest }

        before do
          allow_next_instance_of(UploadService) do |service|
            allow(service).to receive(:execute).and_return(nil)
          end
        end

        it 'returns an error' do
          expect { post_graphql_mutation_with_uploads(mutation, current_user: current_user) }
            .not_to change { Upload.count }

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_blank
          expect(mutation_response['upload']).to be_nil
          expect(mutation_response['markdown']).to be_nil
          expect(mutation_response['url']).to be_nil
          expect(mutation_response['alt']).to be_nil
          expect(mutation_response['fullPath']).to be_nil
          expect(mutation_response['errors']).to contain_exactly('Failed to upload file.')
        end
      end
    end
  end

  context 'when uploading to a project' do
    let(:extra_params) { { project_path: project.full_path } }

    it_behaves_like 'upload creation'
  end

  context 'when uploading to a group' do
    let(:extra_params) { { group_path: group.full_path } }

    before do
      stub_feature_flags(group_uploads_api: group)
    end

    it_behaves_like 'upload creation'

    context 'when feature flag is disabled' do
      let(:current_user) { guest }

      before do
        stub_feature_flags(group_uploads_api: false)
      end

      it 'returns a resource not available error' do
        post_graphql_mutation_with_uploads(mutation, current_user: current_user)

        expect(graphql_errors).to include(
          a_hash_including(
            'message' => "The resource that you are attempting to access does not exist " \
              "or you don't have permission to perform this action"
          )
        )
      end
    end
  end
end
