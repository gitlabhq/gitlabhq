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
      let_it_be(:scope_with_namespace1) { create(:granular_scope, namespace: namespace1, organization: organization) }
      let_it_be(:scope_with_namespace2) { create(:granular_scope, namespace: namespace2, organization: organization) }
      let_it_be(:scope_without_namespace) { create(:granular_scope, :standalone, organization: organization) }

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
    describe 'permissions' do
      where(:permissions, :valid) do
        nil              | false
        'create_issue'   | false
        []               | false
        %w[xxx]          | false
        %w[create_issue] | true
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
    let_it_be(:token_permissions) { ::Authz::Permission.all.keys.take(2) }
    let_it_be(:required_permissions) { token_permissions.first }

    subject { described_class.permitted_for_boundary?(boundary, required_permissions) }

    context 'when a scope exists for a boundary' do
      before do
        create(:granular_scope, namespace: boundary.namespace, permissions: token_permissions)
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
      allow(::Authz::Permission).to receive(:all).and_return((:a..:i).index_with(nil))

      create(:granular_scope, namespace: nil_boundary.namespace, permissions: [:a])
      create(:granular_scope, namespace: rootgroup_boundary.namespace, permissions: [:b, :c])
      create(:granular_scope, namespace: subgroup_boundary.namespace, permissions: [:c, :d])
      create(:granular_scope, namespace: project_boundary.namespace, permissions: [:d, :e])
      create(:granular_scope, namespace: user_boundary.namespace, permissions: [:f, :g])
      create(:granular_scope, namespace: personal_project_boundary.namespace, permissions: [:g, :h])
      create(:granular_scope, :all_membership_namespaces, permissions: [:i])
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

    subject { described_class.token_permissions(boundary) }

    with_them do
      it { is_expected.to match_array(expected_result) }
    end
  end
end
