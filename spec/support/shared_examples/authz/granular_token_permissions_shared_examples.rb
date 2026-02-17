# frozen_string_literal: true

RSpec.shared_examples 'authorizing granular token permissions' do |permissions, expected_success_status: :success|
  shared_examples 'granting access' do
    it 'grants access' do
      request

      expect(response).to have_gitlab_http_status(expected_success_status)
    end
  end

  shared_examples 'denying access' do
    it 'denies access', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:forbidden)

      # Only check JSON body if present (GET/POST/etc have bodies, HEAD doesn't)
      if response.body.present?
        expect(json_response['error']).to eq('insufficient_granular_scope')
        expect(json_response['error_description']).to include(message)
      end
    end
  end

  context 'when authenticating with a legacy personal access token' do
    let(:pat) { create(:personal_access_token, :admin_mode, user:) }

    it_behaves_like 'granting access'
  end

  context 'when authenticating with a granular personal access token' do
    let(:assignables) do
      Array(permissions).map do |permission|
        ::Authz::PermissionGroups::Assignable.for_permission(permission).first&.name
      end
    end

    let(:boundary) { ::Authz::Boundary.for(boundary_object) }
    let(:pat) { create(:granular_pat, user: user, boundary: boundary, permissions: assignables) }

    it_behaves_like 'granting access'

    context 'when the `granular_personal_access_tokens` feature flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: false)
      end

      let(:message) { 'Granular tokens are not yet supported' }

      it_behaves_like 'denying access'
    end

    context 'when an authorizing granular scope is missing' do
      before do
        pat.granular_scopes.delete_all
      end

      let(:message) do
        'Access denied: Your Personal Access Token lacks the required permissions: ' \
          "[#{Array(permissions).join(', ')}]" + (boundary.path ? " for \"#{boundary.path}\"" : '')
      end

      it_behaves_like 'denying access'
    end
  end
end
