# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::OauthApplicationGranularScopes::DeclareService, :aggregate_failures,
  feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:other_group) { create(:group) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:other_organization_group) { create(:group, organization: create(:organization)) }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:group_owner) { create(:user, owner_of: group) }
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:other_user) { create(:user) }

  let_it_be_with_reload(:instance_application) { create(:oauth_application, :without_owner, :granular) }
  let_it_be_with_reload(:group_application) { create(:oauth_application, :group_owned, owner: group) }
  let_it_be_with_reload(:user_application) { create(:oauth_application, owner: user) }
  let_it_be_with_reload(:dynamic_application) { create(:oauth_application, :dynamic) }

  let(:current_user) { admin }
  let(:application) { instance_application }
  let(:access_token) { nil }
  let(:permissions) { %w[read_member_role] }
  let(:mcp_permissions) { %w[execute_mcp_tool] }
  let(:inputs) { [{ access: :user, permissions: mcp_permissions }] }

  subject(:response) do
    described_class.new(
      current_user: current_user, application: application, inputs: inputs, access_token: access_token
    ).execute
  end

  def declared_scope_ids(application)
    application.reload.oauth_application_granular_scopes.map(&:granular_scope_id)
  end

  def access_and_namespace(scopes)
    scopes.map { |scope| [scope.access, scope.namespace_id] }
  end

  shared_examples 'declares nothing' do |reason|
    it "returns #{reason} and leaves the declared set unchanged" do
      scope_ids_before = declared_scope_ids(application)

      expect { response }.not_to change { Authz::GranularScope.count }
      expect(response).to be_error.and have_attributes(reason: reason)
      expect(declared_scope_ids(application)).to match_array(scope_ids_before)
    end
  end

  context 'when the granular_oauth_tokens feature flag is disabled', :enable_admin_mode do
    before do
      stub_feature_flags(granular_oauth_tokens: false)
    end

    it_behaves_like 'declares nothing', :feature_disabled
  end

  context 'with a dynamically registered application', :enable_admin_mode do
    let(:application) { dynamic_application }

    it_behaves_like 'declares nothing', :dynamic_application
  end

  context 'with an instance application' do
    context 'when the actor is an admin in admin mode', :enable_admin_mode do
      context 'with every allowed access level' do
        let(:inputs) do
          [
            { access: :user, permissions: mcp_permissions },
            { access: :instance, permissions: permissions },
            { access: :all_memberships, permissions: permissions },
            { access: :selected_memberships, permissions: permissions,
              group_ids: [other_group.id], project_ids: [project.id] }
          ]
        end

        it 'replaces the declared set and lets the trigger drop the old scope row' do
          old_scope_id = declared_scope_ids(instance_application).sole

          expect { response }.to change { Authz::GranularScope.count }.by(4)
          expect(response).to be_success
          expect(Authz::GranularScope.exists?(old_scope_id)).to be(false)

          scopes = response.payload[:granular_scopes]
          expect(scopes).to all(be_persisted)
          expect(scopes.map(&:organization_id)).to all(eq(instance_application.organization_id))
          expect(access_and_namespace(scopes)).to contain_exactly(
            ['user', nil], ['instance', nil], ['all_memberships', nil],
            ['selected_memberships', other_group.id], ['selected_memberships', project.project_namespace_id]
          )
          expect(instance_application.reload.granular_scopes).to match_array(scopes)
          expect(instance_application.oauth_application_granular_scopes.map(&:organization_id))
            .to all(eq(instance_application.organization_id))
          expect(response.payload[:warnings]).to be_empty
          expect(instance_application.reload.scopes.to_a).to include('granular')
        end

        it 'refreshes an already loaded granular_scopes association' do
          instance_application.granular_scopes.to_a

          response

          expect(instance_application.granular_scopes).to match_array(response.payload[:granular_scopes])
        end
      end

      context 'with personal_projects access' do
        let(:inputs) { [{ access: :personal_projects, permissions: permissions }] }

        it_behaves_like 'declares nothing', :access_not_allowed
      end

      context 'with selected_memberships access and no IDs' do
        let(:inputs) { [{ access: :selected_memberships, permissions: permissions }] }

        it_behaves_like 'declares nothing', :no_resources

        it 'asks for a group or project' do
          expect(response.message).to eq('Selected memberships access requires at least one group or project.')
        end
      end

      context 'with selected_memberships access naming only unknown IDs' do
        let(:inputs) do
          [{ access: :selected_memberships, permissions: permissions,
             group_ids: [non_existing_record_id], project_ids: [non_existing_record_id] }]
        end

        it_behaves_like 'declares nothing', :no_resources
      end

      context 'with a namespace from another organization' do
        let(:inputs) do
          [{ access: :selected_memberships, permissions: permissions, group_ids: [other_organization_group.id] }]
        end

        it_behaves_like 'declares nothing', :invalid

        it 'reports the organization mismatch' do
          expect(response.message).to include('organization must match')
        end
      end

      context 'with no inputs' do
        let(:inputs) { [] }

        it 'clears the declared set without a warning' do
          expect { response }.to change { Authz::GranularScope.count }.by(-1)
          expect(response).to be_success
          expect(response.payload).to eq(granular_scopes: [], warnings: [])
          expect(instance_application.reload.granular?).to be(false)
          expect(instance_application.scopes.to_a).not_to include('granular')
        end
      end

      context 'when no user-level scope grants execute_mcp_tool' do
        let(:inputs) do
          [{ access: :user, permissions: permissions }, { access: :instance, permissions: mcp_permissions }]
        end

        it 'succeeds with a warning' do
          expect(response).to be_success
          expect(response.payload[:warnings]).to contain_exactly(
            'Tokens cannot use the MCP server without a user-level scope granting execute_mcp_tool.'
          )
        end
      end

      context 'with duplicate scopes for the same namespace' do
        let(:inputs) do
          [
            { access: :selected_memberships, permissions: permissions, group_ids: [other_group.id] },
            { access: :selected_memberships, permissions: mcp_permissions, group_ids: [other_group.id] }
          ]
        end

        it_behaves_like 'declares nothing', :duplicate

        it 'names the namespace collision' do
          expect(response.message)
            .to eq('The application cannot have multiple granular scopes for the same namespace')
        end
      end

      context 'with duplicate scopes for the same access level' do
        let(:inputs) { [{ access: :user, permissions: permissions }, { access: :user, permissions: mcp_permissions }] }

        it_behaves_like 'declares nothing', :duplicate

        it 'names the access level collision' do
          expect(response.message)
            .to eq('The application cannot have multiple granular scopes with the same access level')
        end
      end

      context 'when the actor authenticates with a granular token' do
        let_it_be(:access_token) do
          create(:granular_pat, user: admin, boundary: Authz::Boundary.for(:user), permissions: %w[read_member_role])
        end

        context 'when the requested scopes exceed the token' do
          let(:inputs) { [{ access: :instance, permissions: permissions }] }

          it_behaves_like 'declares nothing', :forbidden

          it 'reports the escalation' do
            expect(response.message)
              .to eq('A granular token can only create tokens with equal or lesser permissions.')
          end
        end

        context 'when the requested scopes fit within the token' do
          let(:inputs) { [{ access: :user, permissions: permissions }] }

          it { is_expected.to be_success }
        end
      end
    end

    context 'when the actor is an admin outside admin mode' do
      it_behaves_like 'declares nothing', :forbidden
    end

    context 'when the actor is not an admin' do
      let(:current_user) { user }

      it_behaves_like 'declares nothing', :forbidden
    end
  end

  context 'with a group-owned application' do
    let(:application) { group_application }
    let(:current_user) { group_owner }

    context 'with user and selected_memberships scopes inside the hierarchy' do
      let(:inputs) do
        [
          { access: :user, permissions: mcp_permissions },
          { access: :selected_memberships, permissions: permissions,
            group_ids: [group.id, subgroup.id], project_ids: [project.id] }
        ]
      end

      it 'declares the set' do
        expect { response }.to change { Authz::GranularScope.count }.by(4)
        expect(response).to be_success
        expect(access_and_namespace(group_application.reload.granular_scopes)).to contain_exactly(
          ['user', nil], ['selected_memberships', group.id], ['selected_memberships', subgroup.id],
          ['selected_memberships', project.project_namespace_id]
        )
        expect(group_application.scopes.to_a).to include('granular')
      end
    end

    context 'with an access level that reaches outside the group' do
      where(:access) { [:instance, :all_memberships, :personal_projects] }

      with_them do
        let(:inputs) { [{ access: access, permissions: permissions }] }

        it_behaves_like 'declares nothing', :access_not_allowed
      end
    end

    context 'with a group outside the hierarchy' do
      let(:inputs) { [{ access: :selected_memberships, permissions: permissions, group_ids: [other_group.id] }] }

      it_behaves_like 'declares nothing', :resource_not_allowed
    end

    context 'when the actor does not own the group' do
      let(:current_user) { other_user }

      it_behaves_like 'declares nothing', :forbidden
    end
  end

  context 'with a user-owned application' do
    let(:application) { user_application }
    let(:current_user) { user }

    context 'with personal_projects and user scopes' do
      let(:inputs) do
        [{ access: :personal_projects, permissions: permissions }, { access: :user, permissions: mcp_permissions }]
      end

      it 'declares the set against the owner namespace' do
        expect(response).to be_success
        expect(access_and_namespace(user_application.reload.granular_scopes))
          .to contain_exactly(['personal_projects', user.namespace_id], ['user', nil])
        expect(user_application.scopes.to_a).to include('granular')
      end
    end

    context 'with a group the owner cannot use as a boundary' do
      let(:inputs) { [{ access: :selected_memberships, permissions: permissions, group_ids: [private_group.id] }] }

      it_behaves_like 'declares nothing', :resource_not_allowed
    end

    context 'when the actor is another user' do
      let(:current_user) { other_user }

      it_behaves_like 'declares nothing', :forbidden
    end

    context 'when the actor is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it_behaves_like 'declares nothing', :forbidden
    end
  end
end
