# frozen_string_literal: true

RSpec.shared_examples 'authorizing granular token permissions' do |permissions, expected_success_status: :success,
    context_type: :rest, legacy_token_scopes: nil|
  granular_permissions = Array(permissions)
  individual_permission_labels = granular_permissions.map do |permission|
    assignable = Authz::PermissionGroups::Assignable.for_permission(permission).first
    "#{assignable.resource_name}: #{assignable.action.titleize}"
  end.uniq.sort

  let(:is_graphql) { context_type == :graphql }

  let(:boundary) { ::Authz::Boundary.for(boundary_object) }

  let(:error_boundary_object) { boundary_object }
  let(:acceptable_messages) { [message] }

  shared_examples 'granting access' do
    it 'grants access', :aggregate_failures do
      request

      expect(response).to have_gitlab_http_status(expected_success_status)

      if is_graphql
        expect_graphql_errors_to_be_empty
        expect(graphql_data).to be_present
        expect(graphql_data.values).to all(be_present)

        expect_graphql_mutation_errors_to_be_empty if respond_to?(:mutation)
      end
    end
  end

  shared_examples 'denying access' do
    it 'denies access', :aggregate_failures do
      request

      if is_graphql
        expect(response).to have_gitlab_http_status(:success)

        # queries return nil values when unauthorized, mutations raise an error
        if respond_to?(:mutation)
          expect(graphql_errors).to include(
            a_hash_including('message' => satisfy { |m| acceptable_messages.any? { |e| m.include?(e) } })
          )
        else
          expect(graphql_data.values).to all(
            satisfy { |value| value.nil? || value['nodes'] == [] }
          )
        end
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
    let(:pat) { create(:personal_access_token, :admin_mode, user: user, scopes: legacy_token_scopes || %w[api]) }
    let(:root_ancestor) { boundary.namespace&.root_ancestor }

    it_behaves_like 'granting access'

    context 'when namespace enforces granular tokens' do
      let(:message) { 'Access denied: This operation requires a fine-grained personal access token' }

      before do
        skip 'namespace has no top-level group' unless root_ancestor&.group_namespace?

        stub_feature_flags(granular_personal_access_tokens_enforcement_saas: root_ancestor)

        ::NamespaceSetting.find_by!(namespace_id: root_ancestor.id).update!(
          enforce_granular_tokens: true,
          granular_tokens_enforced_after: Date.current
        )
      end

      it_behaves_like 'denying access'
    end
  end

  context 'when authenticating with a granular personal access token' do
    let(:assignables) do
      granular_permissions.map do |permission|
        ::Authz::PermissionGroups::Assignable.for_permission(permission).first.name
      end.uniq
    end

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

        # Disable the public-access bypass so the "denying access" assertion
        # exercises the missing-scope path. Without this stub the bypass
        # consults `policy_for(nil, ...)` and grants access on public resources,
        # masking the denial we want to verify.
        null_policy = instance_double(::DeclarativePolicy::Base, allowed?: false)
        allow(::DeclarativePolicy).to receive(:policy_for).and_call_original
        allow(::DeclarativePolicy).to receive(:policy_for)
          .with(nil, anything, hash_including(:cache)).and_return(null_policy)
      end

      let(:acceptable_messages) do
        boundary_type_label = ::Authz::Boundary.for(error_boundary_object).type_label
        prefix = "Access denied: This operation requires a fine-grained personal access token " \
          "with the following #{boundary_type_label} permissions:"
        (individual_permission_labels + [individual_permission_labels.join(', ')]).uniq
          .map { |label| "#{prefix} [#{label}]." }
      end

      let(:message) { acceptable_messages.last }

      it_behaves_like 'denying access'
    end

    # A granular PAT reaches a public resource only through the public-access bypass, which mirrors
    # anonymous access. We compare against a legacy non-member because a true anonymous request 401s
    # on authenticate! endpoints. That baseline only holds for reads: an authenticated non-member can
    # write to public resources while the bypass (anonymous) cannot. So we branch on the HTTP verb
    # rather than the permission name, which keeps this correct for any read permission (read_*,
    # download_*, use_global_search, ...). Dispatching the scopeless granular token is safe even for
    # writes: it is denied at the boundary before the endpoint runs, so nothing mutates.
    if context_type != :graphql
      context 'when compared to a legacy non-member request' do
        it 'mirrors the legacy non-member outcome via the public-access bypass' do
          unless boundary_object.is_a?(::Project) || boundary_object.is_a?(::Group)
            skip 'only meaningful on Project/Group boundaries'
          end

          # The public-access bypass only grants access on public resources. On internal or private
          # resources an authenticated non-member may still read (internal visibility), which the
          # bypass does not and should not mirror.
          skip 'public-access bypass only applies to public resources' unless boundary_object.public?

          non_member = create(:user)
          granular_granted = dispatch_request_as(create(:granular_pat, user: non_member))

          if response.request.get?
            # Read: the bypass must grant the same access a legacy non-member has.
            expect(granular_granted).to eq(dispatch_request_as(create(:personal_access_token, user: non_member)))
          else
            # Write: the bypass must never grant a mutation; legacy is not dispatched (no side effects).
            expect(granular_granted).to be(false)
          end
        end
      end
    end
  end

  # Re-dispatches the caller-defined `let(:request)` with a different `pat`.
  # Stubs `pat` and invalidates the let memoization so `request` re-evaluates.
  #
  # Implementation notes:
  # - We reach into `__memoized` because RSpec offers no public API for
  #   per-key memoization invalidation. Verified against rspec-core 3.13;
  #   if its internal storage layout changes this is the line to update.
  # - The rescue is scoped to NoMethodError on a nil-stubbed pat: some
  #   callers reference `pat.token` directly (e.g. basic auth headers).
  #   We don't short-circuit `nil` because callers that pass `pat` to
  #   helpers which gracefully accept a nil token should still dispatch:
  #   that path actually exercises anonymous HTTP and surfaces drift
  #   between policy-based bypass and HTTP-level authz.
  def dispatch_request_as(new_pat)
    allow(self).to receive(:pat).and_return(new_pat)
    __memoized.instance_variable_get(:@memoized).delete(:request)

    request
    response.successful?
  rescue NoMethodError
    raise unless new_pat.nil?

    false
  end
end

RSpec.shared_examples 'authorizing granular token permissions for GraphQL' do |permissions|
  # `include_examples` (not `it_behaves_like`) so the inner example group's
  # default `let` definitions (e.g. `error_boundary_object`) land on this
  # group and remain overridable from the caller's customization block.
  include_examples 'authorizing granular token permissions', permissions, context_type: :graphql
end

RSpec.shared_examples 'authorizing granular token permissions for GraphQL with a skipped child type' do |permissions|
  context 'when a granular token authorizes the parent type' do
    let(:assignables) do
      Array(permissions).map do |permission|
        ::Authz::PermissionGroups::Assignable.for_permission(permission).min_by(&:name).name
      end.uniq
    end

    let(:pat) do
      create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(boundary_object), permissions: assignables)
    end

    it 'returns the data of the type that skips granular token authorization', :aggregate_failures do
      request

      expect(graphql_errors).to be_nil
      expect(graphql_data_at(*skipped_data_path)).to be_present
    end
  end

  context 'when a granular token does not authorize the parent type' do
    let(:pat) { create(:granular_pat, user: user, boundary: ::Authz::Boundary.for(boundary_object)) }

    it 'does not return the data of the type that skips granular token authorization', :aggregate_failures do
      request

      expect(graphql_errors).to be_nil
      expect(graphql_data_at(*skipped_data_path)).to be_nil
    end
  end
end
