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
  end

  describe '#expanded_permissions' do
    let(:scope) { build(:granular_scope, permissions: permissions) }

    subject(:expanded) { scope.expanded_permissions }

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:get).and_call_original
      allow(::Authz::PermissionGroups::Assignable).to receive(:get).with('group_a')
        .and_return(instance_double(::Authz::PermissionGroups::Assignable, permissions: [:perm_1, :perm_2]))
      allow(::Authz::PermissionGroups::Assignable).to receive(:get).with('group_b')
        .and_return(instance_double(::Authz::PermissionGroups::Assignable, permissions: [:perm_3]))
      allow(::Authz::PermissionGroups::Assignable).to receive(:get).with('unknown').and_return(nil)
    end

    context 'with known assignable permission group names' do
      let(:permissions) { %w[group_a group_b] }

      it { is_expected.to match_array([:perm_1, :perm_2, :perm_3]) }
    end

    context 'with an unknown assignable permission group name' do
      let(:permissions) { %w[group_a unknown] }

      it 'silently drops the unknown name' do
        is_expected.to match_array([:perm_1, :perm_2])
      end
    end

    context 'with nil permissions' do
      let(:permissions) { nil }

      it { is_expected.to eq([]) }
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

  describe '#applicable_to_boundary?' do
    subject(:applicable_scopes) do
      scopes.values.select { |scope| scope.applicable_to_boundary?(boundary) }
    end

    where(:boundary, :applicable_scope_types) do
      ref(:instance_boundary)        | [:instance]
      ref(:standalone_user_boundary) | [:standalone_user]
      ref(:rootgroup_boundary)       | [:all_memberships, :rootgroup]
      ref(:subgroup_boundary)        | [:all_memberships, :rootgroup, :subgroup]
      ref(:project_boundary)         | [:all_memberships, :rootgroup, :subgroup, :project]
      ref(:user_project_boundary)    | [:all_memberships, :personal_projects, :user_project]
      ref(:other_project_boundary)   | [:all_memberships, :other_project]
    end

    with_them do
      it { is_expected.to match_array(scopes_for(*applicable_scope_types)) }
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
