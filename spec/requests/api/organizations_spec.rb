# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Organizations, feature_category: :cell do
  include WorkhorseHelpers

  let(:user) { create(:user) }

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

    context 'when user is not authorized' do
      it 'returns unauthorized' do
        post api("/organizations"), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(allow_organization_creation: false)
      end

      it 'returns forbidden' do
        post api("/organizations", user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when user is authorized' do
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
        let(:current_user) { user }

        def request
          post api("/organizations", user), params: params
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
end
