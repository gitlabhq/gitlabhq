# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Organizations, feature_category: :organization do
  include WorkhorseHelpers

  let_it_be(:user) { create(:user) }

  shared_examples 'organization avatar upload' do
    context 'when valid' do
      let(:file_path) { 'spec/fixtures/banana_sample.gif' }

      it 'returns avatar url in response' do
        make_upload_request

        organization_id = json_response['id']
        avatar_url = "http://localhost/uploads/-/system/organizations/organization_detail/avatar/#{organization_id}/banana_sample.gif"
        expect(json_response['avatar_url']).to eq(avatar_url)
      end
    end

    context 'when invalid' do
      shared_examples 'invalid file upload request' do
        it 'returns 400', :aggregate_failures do
          make_upload_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.message).to eq('Bad Request')
          expect(json_response['message'].to_s).to match(/#{message}/)
        end
      end

      context 'when file format is not supported' do
        let(:file_path) { 'spec/fixtures/doc_sample.txt' }
        let(:message) { 'file format is not supported. Please try one of the following supported formats: image/png' }

        it_behaves_like 'invalid file upload request'
      end

      context 'when file is too large' do
        let(:file_path) { 'spec/fixtures/big-image.png' }
        let(:message)   { 'is too big' }

        it_behaves_like 'invalid file upload request'
      end
    end
  end

  describe 'POST /organizations' do
    let(:base_params) do
      {
        name: 'New Organization',
        path: 'new-org',
        description: 'A new organization'
      }
    end

    let(:params) { base_params }

    context 'when on GitLab.com', :saas do
      it_behaves_like 'authorizing granular token permissions', :create_organization do
        let(:boundary_object) { :instance }
        let(:request) { post api('/organizations', personal_access_token: pat), params: base_params }
      end
    end

    context 'when user is not authorized' do
      it 'returns unauthorized' do
        post api("/organizations"), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(organization_switching: false)
      end

      it 'returns forbidden' do
        post api("/organizations", user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when on self-managed' do
      it 'returns forbidden' do
        post api("/organizations", user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is authorized', :saas do
      it_behaves_like 'organization avatar upload' do
        def make_upload_request
          params_with_file_upload = params.merge(avatar: fixture_file_upload(file_path))

          workhorse_form_with_file(
            api('/organizations', user),
            method: :post,
            file_key: :avatar,
            params: params_with_file_upload
          )
        end
      end

      it_behaves_like 'rate limited endpoint', rate_limit_key: :create_organization_api do
        let_it_be(:user2) { create(:user) }

        let(:current_user) { user }

        def request
          post api("/organizations", user), params: params
        end

        def request_with_second_scope
          post api("/organizations", user2), params: params
        end
      end

      shared_examples 'returns bad request' do
        specify do
          post api("/organizations", user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      it 'creates a new organization' do
        post api("/organizations", user), params: params

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['name']).to eq('New Organization')
        expect(json_response['path']).to eq('new-org')
        expect(json_response['description']).to eq('A new organization')
        expect(json_response['visibility']).to eq('private')
      end

      context 'when visibility is provided' do
        it 'creates a public organization' do
          post api("/organizations", user), params: base_params.merge(visibility: 'public')

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['visibility']).to eq('public')
        end

        it 'returns error for internal organization' do
          post api("/organizations", user), params: base_params.merge(visibility: 'internal')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('visibility does not have a valid value')
        end
      end

      context 'when optional params are missing' do
        context 'with missing description' do
          let(:params) { base_params.except(:description) }

          it 'creates a new organization' do
            post api("/organizations", user), params: params

            expect(response).to have_gitlab_http_status(:success)
            expect(json_response['name']).to eq('New Organization')
            expect(json_response['path']).to eq('new-org')
          end
        end
      end

      context 'when required params are missing' do
        context 'with missing name' do
          let(:params) { base_params.except(:name) }

          it_behaves_like 'returns bad request'
        end

        context 'with missing path' do
          let(:params) { base_params.except(:path) }

          it_behaves_like 'returns bad request'
        end
      end

      context 'when organization creation fails' do
        it 'returns an error message' do
          message = _('Failed to create organization')
          allow_next_instance_of(::Organizations::CreateService) do |service|
            allow(service).to receive(:execute).and_return(ServiceResponse.error(message: Array(message)))
          end

          post api("/organizations", user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to match_array(message)
        end
      end

      context 'when organization creation is disable by admin' do
        before do
          stub_application_setting(can_create_organization: false)
        end

        it 'returns forbidden' do
          post api("/organizations", user), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /organizations/:id' do
    let_it_be_with_refind(:organization) { create(:organization) }

    it_behaves_like 'authorizing granular token permissions', :delete_organization do
      let(:boundary_object) { :instance }
      let(:request) { delete api("/organizations/#{organization.id}", personal_access_token: pat) }

      before do
        create(:organization_user, :owner, organization: organization, user: user)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized' do
        delete api("/organizations/#{organization.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user does not have permission' do
      it 'returns forbidden with an error message' do
        delete api("/organizations/#{organization.id}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('Insufficient permissions')
      end
    end

    context 'when user has permission' do
      before_all do
        create(:organization_user, :owner, organization: organization, user: user)
      end

      context 'when organization does not exist' do
        it 'returns not found' do
          delete api("/organizations/#{non_existing_record_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when organization is not empty' do
        before do
          create(:group, organization: organization)
        end

        it 'returns bad request with an error message' do
          delete api("/organizations/#{organization.id}", user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Organization must be empty before it can be deleted')
        end
      end

      context 'when organization is already soft-deleted' do
        before do
          ::Organizations::SoftDeleteService.new(organization, current_user: user).execute
          organization.reload
        end

        it 'returns bad request with an error message' do
          delete api("/organizations/#{organization.id}", user)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']).to eq('Organization has already been deleted')
        end
      end

      context 'when organization is empty and not default' do
        it 'soft-deletes the organization and returns accepted' do
          expect { delete api("/organizations/#{organization.id}", user) }
            .to change { organization.reload.state }.from('active').to('soft_deleted')

          expect(response).to have_gitlab_http_status(:accepted)
        end
      end
    end
  end
end
