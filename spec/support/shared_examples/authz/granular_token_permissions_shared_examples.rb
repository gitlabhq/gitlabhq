# frozen_string_literal: true

RSpec.shared_examples 'authorizing granular token permissions' do |permissions, expected_success_status: :success,
    context_type: :rest|
  let(:is_graphql) { context_type == :graphql }
  let(:error_boundary_object) { boundary_object }

  shared_examples 'granting access' do
    it 'grants access', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(expected_success_status)
      expect(graphql_errors).to be_nil if is_graphql
    end
  end

  shared_examples 'denying access' do
    it 'denies access', :aggregate_failures do
      request

      if is_graphql
        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to include(a_hash_including('message' => include(message)))
      else
        expect(response).to have_gitlab_http_status(:forbidden)

        # Only check JSON body if present (GET/POST/etc have bodies, HEAD doesn't)
        if response.body.present?
          expect(json_response['error']).to eq('insufficient_granular_scope')
          expect(json_response['error_description']).to include(message)
        end
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
        ::Authz::PermissionGroups::Assignable.for_permission(permission).first.name
      end
    end

    let(:boundary) { ::Authz::Boundary.for(boundary_object) }
    let(:pat) { create(:granular_pat, user: user, boundary: boundary, permissions: assignables) }

    it_behaves_like 'granting access'

    context 'when the `granular_personal_access_tokens` feature flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: false)
      end

      let(:message) { 'Access denied: Fine-grained personal access tokens are not yet supported.' }

      it_behaves_like 'denying access'
    end

    context 'when an authorizing granular scope is missing' do
      before do
        pat.granular_scopes.delete_all
      end

      missing_permission_labels = Array(permissions).map do |permission|
        assignable = Authz::PermissionGroups::Assignable.for_permission(permission).first
        "#{assignable.resource_name}: #{assignable.action.titleize}"
      end.uniq.sort.join(', ')

      let(:message) do
        boundary_type_label = ::Authz::Boundary.for(error_boundary_object).type_label

        "Access denied: This operation requires a fine-grained personal access token " \
          "with the following #{boundary_type_label} permissions: [#{missing_permission_labels}]."
      end

      it_behaves_like 'denying access'
    end
  end
end

RSpec.shared_examples 'authorizing granular token permissions for GraphQL' do |permissions|
  it_behaves_like 'authorizing granular token permissions', permissions, context_type: :graphql
end
