# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organizations::Auth', :with_current_organization, feature_category: :system_access do
  include LoginHelpers
  include_context 'with IAM authentication setup'

  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, organizations: [organization]) }
  let_it_be(:provider) { 'google_oauth2' }
  let_it_be(:extern_uid) { '12345' }

  let(:iam_service_url) { 'https://iam.service' }
  let(:iam_audience) { 'iam-auth-client-handler' }
  let(:jwt_payload) do
    {
      iss: iam_service_url,
      aud: iam_audience,
      exp: 1.minute.from_now.to_i,
      provider: provider,
      user_info: { id: extern_uid, name: user.name, email: user.email }
    }
  end

  let(:valid_jwt) { JWT.encode(jwt_payload, private_key, 'RS256', { kid: kid }) }
  let(:state) { SecureRandom.hex(32) }
  let(:params) { { userinfo: valid_jwt, organization_organization_path: organization.path, state: state } }

  before do
    stub_current_organization(organization)
    stub_feature_flags(iam_svc_login: true)
  end

  describe 'POST /organizations/:organization_path/auth/complete' do
    subject(:complete_request) { post organization_auth_complete_path(organization), params: params }

    context 'with valid identity and valid state' do
      let!(:identity) { create(:identity, provider: provider, extern_uid: extern_uid, user: user) }

      before do
        cookies['iam_auth_state'] = state
      end

      it 'signs in the user' do
        complete_request
        expect(response).to redirect_to(root_path)
      end

      it 'clears the state cookie after successful validation' do
        complete_request
        expect(cookies['iam_auth_state']).to be_empty
      end
    end

    context 'with valid identity but missing state' do
      let!(:identity) { create(:identity, provider: provider, extern_uid: extern_uid, user: user) }

      it 'returns unauthorized' do
        complete_request
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with valid identity but mismatched state' do
      let!(:identity) { create(:identity, provider: provider, extern_uid: extern_uid, user: user) }

      before do
        cookies['iam_auth_state'] = SecureRandom.hex(32)
      end

      it 'returns unauthorized' do
        complete_request
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with invalid JWT' do
      let(:params) { super().merge(userinfo: 'invalid.token') }

      before do
        cookies['iam_auth_state'] = state
      end

      it 'returns error' do
        complete_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when organization is not found' do
      let!(:params) { { userinfo: valid_jwt, state: state } }
      let(:organization) { Organizations::Organization.new(path: 'non-existent') }

      let!(:identity) { create(:identity, provider: provider, extern_uid: extern_uid, user: user) }

      before do
        cookies['iam_auth_state'] = state
      end

      it 'renders organization not found error' do
        complete_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user\'s home organization is different' do
      let(:other_organization) { create(:organization) }
      let(:user) { create(:user, organizations: [other_organization]) }

      before do
        cookies['iam_auth_state'] = state
      end

      it 'renders unauthorized error' do
        complete_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with FF iam_svc_login disabled' do
      before do
        stub_feature_flags(iam_svc_login: true)
      end

      it "returns forbidden" do
        complete_request
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
