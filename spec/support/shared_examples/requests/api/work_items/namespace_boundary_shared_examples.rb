# frozen_string_literal: true

# Requires from the caller:
#   project - the project the granular token is scoped to
#   user    - the token owner, a member of `project`
#   request - the request against `/namespaces/#{numeric_group.path}/...`, authenticated with `pat`
RSpec.shared_examples 'a namespace work item route resolving the token boundary by path' do |permission|
  context 'when a granular token is scoped to a project whose ID matches a group path' do
    # Set after creation to bypass the two-character minimum, as a fresh database yields single-digit IDs.
    let(:numeric_group) do
      create(:group, :private, reporters: user).tap { |group| group.update_attribute(:path, project.id.to_s) }
    end

    let(:pat) do
      create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(project),
        permissions: [::Authz::PermissionGroups::Assignable.for_permission(permission).first.name])
    end

    it 'denies the request with the project-scoped token', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(json_response['error']).to eq('insufficient_granular_scope')
    end
  end
end
