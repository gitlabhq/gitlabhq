# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::GranularScope, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:rootgroup) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: rootgroup) }
  let_it_be(:project) { create(:project, namespace: subgroup) }
  let_it_be(:user) { create(:user, :with_namespace) }
  let_it_be(:user_project) { create(:project, namespace: user.namespace) }
  let_it_be(:other_project) { create(:project) }

  let_it_be(:instance_boundary) { Authz::Boundary.for(:instance) }
  let_it_be(:standalone_user_boundary) { Authz::Boundary.for(:user) }
  let_it_be(:all_memberships_boundary) { Authz::Boundary.for(:all_memberships) }
  let_it_be(:rootgroup_boundary) { Authz::Boundary.for(rootgroup) }
  let_it_be(:subgroup_boundary) { Authz::Boundary.for(subgroup) }
  let_it_be(:project_boundary) { Authz::Boundary.for(project) }
  let_it_be(:personal_projects_boundary) { Authz::Boundary.for(user) }
  let_it_be(:user_project_boundary) { Authz::Boundary.for(user_project) }
  let_it_be(:other_project_boundary) { Authz::Boundary.for(other_project) }

  let_it_be(:scopes) do
    {
      instance: build(:granular_scope, boundary: instance_boundary, permissions: [:instance_perm]),
      standalone_user: build(:granular_scope, boundary: standalone_user_boundary, permissions: [:standalone_user_perm]),
      all_memberships: build(:granular_scope, boundary: all_memberships_boundary, permissions: [:all_memberships_perm]),
      rootgroup: build(:granular_scope, boundary: rootgroup_boundary, permissions: [:rootgroup_perm]),
      subgroup: build(:granular_scope, boundary: subgroup_boundary, permissions: [:subgroup_perm]),
      project: build(:granular_scope, boundary: project_boundary, permissions: [:project_perm]),
      personal_projects:
        build(:granular_scope, boundary: personal_projects_boundary, permissions: [:personal_projects_perm]),
      user_project: build(:granular_scope, boundary: user_project_boundary, permissions: [:user_project_perm]),
      other_project: build(:granular_scope, boundary: other_project_boundary, permissions: [:other_project_perm])
    }.each_value { |scope| scope.save!(validate: false) }
  end

  def scopes_for(*types)
    scopes.slice(*types).values
  end

  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'scopes' do
    describe '.with_namespace' do
      it 'returns scopes for the given namespace' do
        expect(described_class.with_namespace(subgroup)).to match_array(scopes_for(:subgroup))
      end

      it 'returns empty when namespace_id is nil' do
        expect(described_class.with_namespace(nil))
          .to match_array(scopes_for(:instance, :standalone_user, :all_memberships))
      end

      it 'returns empty when namespace does not exist' do
        expect(described_class.with_namespace(-1)).to be_empty
      end
    end

    describe '.for_standalone' do
      it 'returns standalone instance and user scopes', :aggregate_failures do
        expect(described_class.for_standalone(:personal_projects)).to be_empty
        expect(described_class.for_standalone(:all_memberships)).to be_empty
        expect(described_class.for_standalone(:selected_memberships)).to be_empty
        expect(described_class.for_standalone(:user)).to match_array(scopes_for(:standalone_user))
        expect(described_class.for_standalone(:instance)).to match_array(scopes_for(:instance))
      end
    end

    describe '.for_namespaces' do
      it 'returns personal_projects, selected_memberships and all_memberships scopes', :aggregate_failures do
        expect(described_class.for_namespaces(rootgroup))
          .to match_array(scopes_for(:all_memberships, :rootgroup))

        expect(described_class.for_namespaces(subgroup.self_and_ancestor_ids))
          .to match_array(scopes_for(:all_memberships, :rootgroup, :subgroup))

        expect(described_class.for_namespaces(project.project_namespace.self_and_ancestor_ids))
          .to match_array(scopes_for(:all_memberships, :rootgroup, :subgroup, :project))

        expect(described_class.for_namespaces(user.namespace))
          .to match_array(scopes_for(:all_memberships, :personal_projects))

        expect(described_class.for_namespaces(user_project.project_namespace.self_and_ancestor_ids))
          .to match_array(scopes_for(:all_memberships, :personal_projects, :user_project))

        expect(described_class.for_namespaces(other_project.project_namespace.self_and_ancestor_ids))
          .to match_array(scopes_for(:all_memberships, :other_project))
      end
    end
  end

  describe 'validations' do
    # Actual permission with existing YAML definition file in
    # config/authz/permission_groups/assignable_permissions/
    let(:permission) { :create_member_role }

    describe 'permissions' do
      where(:permissions, :valid) do
        nil                | false
        ref(:permission)   | false
        []                 | false
        %w[xxx]            | false
        [ref(:permission)] | true
      end

      with_them do
        subject { build(:granular_scope, permissions:).valid? }

        it { is_expected.to eq(valid) }
      end
    end

    describe 'organization_match' do
      let(:scope_organization) { create(:organization) }

      subject(:scope) { build(:granular_scope, organization: scope_organization, namespace: namespace) }

      context 'when the scope has no boundary' do
        let(:namespace) { nil }

        it { is_expected.to be_valid }
      end

      context "when the scope's namespace is from the same organization" do
        let(:namespace) { build(:namespace, organization: scope_organization) }

        it { is_expected.to be_valid }
      end

      context "when the scope's namespace is from a different organization" do
        let(:namespace) { build(:namespace) }

        it 'is invalid and adds an error message to namespace' do
          expect(scope).to be_invalid
          expect(scope.errors[:namespace]).to include("organization must match the token scope's organization")
        end
      end
    end
  end

  describe '.permitted_for_boundary?' do
    let_it_be(:project) { create(:project) }
    let_it_be(:boundary) { Authz::Boundary.for(project) }

    subject { described_class.permitted_for_boundary?(boundary, required_permissions) }

    shared_examples 'checks for permission on boundary' do
      context 'when a scope exists for a boundary' do
        before do
          create(:granular_scope, boundary: boundary, permissions: token_permissions)
        end

        it { is_expected.to be true }

        context 'when the scope does not include the required permissions' do
          let_it_be(:required_permissions) { :not_allowed_permission }

          it { is_expected.to be false }
        end
      end

      context 'when a scope does not exist for a boundary' do
        it { is_expected.to be false }
      end
    end

    context 'with individual permissions' do
      let_it_be(:token_permissions) { %i[create_member_role delete_member_role] }
      let_it_be(:required_permissions) { :delete_member_role }

      it_behaves_like 'checks for permission on boundary'
    end

    context 'with grouped permissions' do
      let_it_be(:token_permissions) do
        %i[update_wiki] # expands to :update_wiki and :upload_wiki_attachment raw permissions
      end

      let_it_be(:required_permissions) { :upload_wiki_attachment }

      it_behaves_like 'checks for permission on boundary'
    end
  end

  describe '.token_permissions' do
    where(:boundary, :expected_result) do
      ref(:instance_boundary)        | [:instance_perm]
      ref(:standalone_user_boundary) | [:standalone_user_perm]
      ref(:rootgroup_boundary)       | [:all_memberships_perm, :rootgroup_perm]
      ref(:subgroup_boundary)        | [:all_memberships_perm, :rootgroup_perm, :subgroup_perm]
      ref(:project_boundary)         | [:all_memberships_perm, :rootgroup_perm, :subgroup_perm, :project_perm]
      ref(:user_project_boundary)    | [:all_memberships_perm, :personal_projects_perm, :user_project_perm]
      ref(:other_project_boundary)   | [:all_memberships_perm, :other_project_perm]
    end

    let_it_be(:assignable_permissions) do
      %i[instance_perm standalone_user_perm all_memberships_perm rootgroup_perm subgroup_perm project_perm
        personal_projects_perm user_project_perm other_project_perm]
    end

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return(assignable_permissions.index_with { |p|
        instance_double(::Authz::PermissionGroups::Assignable, permissions: [p])
      })
    end

    subject(:permissions) { described_class.token_permissions(boundary) }

    with_them do
      it { is_expected.to match_array(expected_result) }
    end

    describe 'persisted but undefined assignable permission group' do
      let(:boundary) { instance_boundary }

      before do
        build(:granular_scope, boundary: boundary, permissions: [:non_existing]).save!(validate: false)
      end

      it 'is ignored' do
        expect(permissions).to match_array([:instance_perm])
      end
    end

    describe 'when the passed boundary is `nil` or has the incorrect access' do
      where(:boundary) do
        [
          ref(:all_memberships_boundary),
          ref(:personal_projects_boundary),
          nil
        ]
      end

      with_them do
        it 'is expected to raise an error' do
          expect { permissions }.to raise_error { NoMethodError }
        end
      end
    end
  end

  describe '#build_copy' do
    let_it_be(:organization) { create(:organization) }
    let_it_be(:group) { create(:group, organization: organization) }
    let_it_be(:original_scope) do
      create(:granular_scope, :selected_memberships,
        organization: organization,
        namespace: group,
        permissions: %w[create_member_role delete_member_role])
    end

    subject(:copied_scope) { original_scope.build_copy }

    it 'builds a new GranularScope with the same attributes' do
      expect(copied_scope).not_to be_persisted

      described_class::COPYABLE_ATTRIBUTES.each do |attr|
        expect(copied_scope.attributes[attr]).to eq(original_scope.attributes[attr])
      end
    end
  end
end
