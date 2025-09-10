# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::GranularScope, feature_category: :permissions do
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
      let_it_be(:instance_scope) { create(:granular_scope, :instance, organization: organization) }

      it 'returns scopes for the given namespace' do
        expect(described_class.with_namespace(namespace1.id)).to contain_exactly(scope_with_namespace1)
      end

      it 'returns empty when namespace_id is nil' do
        expect(described_class.with_namespace(nil)).to contain_exactly(instance_scope)
      end

      it 'returns empty when namespace does not exist' do
        expect(described_class.with_namespace(-1)).to be_empty
      end

      it 'does not return scopes for other namespaces' do
        result = described_class.with_namespace(namespace1.id)
        expect(result).not_to include(scope_with_namespace2, instance_scope)
      end
    end
  end

  describe 'validations' do
    describe 'permissions' do
      using RSpec::Parameterized::TableSyntax

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

      context 'when the scope is instance-level' do
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

  describe '#boundary' do
    subject { build(:granular_scope, namespace:).boundary }

    context 'when namespace is a group' do
      let(:namespace) { build(:group) }

      it { is_expected.to eq('Group') }
    end

    context 'when namespace is a project namespace' do
      let(:namespace) { build(:project_namespace) }

      it { is_expected.to eq('Project') }
    end

    context 'when namespace is a user namespace' do
      let(:namespace) { build(:user_namespace) }

      it { is_expected.to eq('User') }
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it { is_expected.to eq('Instance') }
    end
  end
end
