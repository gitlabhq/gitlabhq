# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::GranularScope, feature_category: :permissions do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'scopes' do
    describe '.with_namespace' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:namespace1) { create(:namespace, organization: organization) }
      let_it_be(:namespace2) { create(:namespace, organization: organization) }
      let_it_be(:scope_with_namespace1) do
        create(:granular_scope, :selected_memberships, namespace: namespace1, organization: organization)
      end

      let_it_be(:scope_with_namespace2) do
        create(:granular_scope, :selected_memberships, namespace: namespace2, organization: organization)
      end

      let_it_be(:scope_without_namespace) { create(:granular_scope, :user, organization: organization) }

      it 'returns scopes for the given namespace' do
        expect(described_class.with_namespace(namespace1.id)).to contain_exactly(scope_with_namespace1)
      end

      it 'returns empty when namespace_id is nil' do
        expect(described_class.with_namespace(nil)).to contain_exactly(scope_without_namespace)
      end

      it 'returns empty when namespace does not exist' do
        expect(described_class.with_namespace(-1)).to be_empty
      end

      it 'does not return scopes for other namespaces' do
        result = described_class.with_namespace(namespace1.id)
        expect(result).not_to include(scope_with_namespace2, scope_without_namespace)
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
        let(:other_organization) { create(:organization) }
        let(:namespace) { build(:namespace, organization: other_organization) }

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
          create(:granular_scope, :selected_memberships, namespace: boundary.namespace,
            permissions: token_permissions)
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
        %i[edit_wiki] # expands to :update_wiki and :upload_wiki_attachment raw permissions
      end

      let_it_be(:required_permissions) { :upload_wiki_attachment }

      it_behaves_like 'checks for permission on boundary'
    end
  end

  describe '.token_permissions' do
    let_it_be(:rootgroup) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: rootgroup) }
    let_it_be(:project) { create(:project, namespace: subgroup) }
    let_it_be(:user) { create(:user, :with_namespace) }
    let_it_be(:personal_project) { create(:project, namespace: user.namespace) }

    let_it_be(:nil_boundary) { Authz::Boundary.for(nil) }
    let_it_be(:rootgroup_boundary) { Authz::Boundary.for(rootgroup) }
    let_it_be(:subgroup_boundary) { Authz::Boundary.for(subgroup) }
    let_it_be(:project_boundary) { Authz::Boundary.for(project) }
    let_it_be(:user_boundary) { Authz::Boundary.for(user) }
    let_it_be(:personal_project_boundary) { Authz::Boundary.for(personal_project) }
    let_it_be(:other_namespace_boundary) { Authz::Boundary.for(create(:project)) }

    before do
      allow(::Authz::PermissionGroups::Assignable).to receive(:all).and_return((:a..:i).index_with { |p|
        instance_double(::Authz::PermissionGroups::Assignable, permissions: [p])
      })

      create(:granular_scope, :instance, permissions: [:a])
      create(:granular_scope, :selected_memberships, namespace: rootgroup_boundary.namespace, permissions: [:b, :c])
      create(:granular_scope, :selected_memberships, namespace: subgroup_boundary.namespace, permissions: [:c, :d])
      create(:granular_scope, :selected_memberships, namespace: project_boundary.namespace, permissions: [:d, :e])
      create(:granular_scope, :personal_projects, namespace: user_boundary.namespace, permissions: [:f, :g])
      create(:granular_scope, :selected_memberships, namespace: personal_project_boundary.namespace,
        permissions: [:g, :h])
      create(:granular_scope, :all_memberships, permissions: [:i])
    end

    where(:boundary, :expected_result) do
      ref(:nil_boundary)              | [:a, :i]
      ref(:rootgroup_boundary)        | [:b, :c, :i]
      ref(:subgroup_boundary)         | [:b, :c, :d, :i]
      ref(:project_boundary)          | [:b, :c, :d, :e, :i]
      ref(:user_boundary)             | [:f, :g, :i]
      ref(:personal_project_boundary) | [:f, :g, :h, :i]
      ref(:other_namespace_boundary)  | [:i]
    end

    subject(:permissions) { described_class.token_permissions(boundary) }

    with_them do
      it { is_expected.to match_array(expected_result) }
    end

    describe 'persisted but undefined assignable permission group' do
      let(:boundary) { nil_boundary }

      before do
        build(:granular_scope, :instance, permissions: [:non_existing]).save!(validate: false)
      end

      it 'is ignored' do
        expect(permissions).to match_array([:a, :i])
      end
    end
  end
end
