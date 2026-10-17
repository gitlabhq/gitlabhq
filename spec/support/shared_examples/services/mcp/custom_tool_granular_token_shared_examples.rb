# frozen_string_literal: true

# Requires `service`, `tool_params`, `current_user` and `boundary_resource`.
RSpec.shared_examples 'an MCP custom tool authorizing granular tokens' do |permission|
  let(:token) { create(:granular_pat, user: current_user) }

  it "checks #{permission} on the target's boundary" do
    authorize_service = instance_double(
      ::Authz::Tokens::AuthorizeGranularScopesService, execute: ServiceResponse.success
    )

    expect(::Authz::Tokens::AuthorizeGranularScopesService).to receive(:new).with(
      boundaries: an_object_having_attributes(boundary: boundary_resource),
      permissions: [permission],
      token: token
    ).and_return(authorize_service)

    service.set_cred(current_user: current_user, access_token: token)
    service.execute(request: nil, params: tool_params)
  end

  it "declares #{permission} for the target's boundary type" do
    boundary_types = ::Authz::PermissionGroups::Assignable.for_permission(permission).flat_map(&:boundaries)

    expect(boundary_types.map(&:to_s)).to include(::Authz::Boundary.for(boundary_resource).type_label)
  end
end
