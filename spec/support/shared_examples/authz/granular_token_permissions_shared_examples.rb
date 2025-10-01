# frozen_string_literal: true

RSpec.shared_examples 'authorizing granular token permissions' do |permissions|
  shared_examples 'granting access' do
    it 'grants access' do
      request

      expect(response).to have_gitlab_http_status(:success)
    end
  end

  shared_examples 'denying access' do
    it 'denies access', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['error']).to eq('insufficient_granular_scope')
      expect(json_response['error_description']).to eq(message)
    end
  end

  context 'when authenticating with a legacy personal access token' do
    let(:pat) { create(:personal_access_token, user:) }

    it_behaves_like 'granting access'
  end

  context 'when authenticating with a granular personal access token' do
    let(:boundary) { ::Authz::Boundary.for(boundary_object) }
    let(:pat) { create(:granular_pat, user: user, namespace: boundary.namespace, permissions: permissions) }

    it_behaves_like 'granting access'

    context 'when the `authorize_granular_pats` feature flag is disabled' do
      before do
        stub_feature_flags(authorize_granular_pats: false)
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
          "[#{Array(permissions).join(', ')}] for \"#{boundary.path}\"."
      end

      it_behaves_like 'denying access'
    end
  end
end
