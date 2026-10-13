# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularScopes::UniquenessCheck, feature_category: :permissions do
  let_it_be(:group) { create(:group) }
  let_it_be(:other_group) { create(:group) }

  let(:group_scope) { build(:granular_scope, boundary: Authz::Boundary.for(group)) }
  let(:same_group_scope) { build(:granular_scope, boundary: Authz::Boundary.for(group)) }
  let(:other_group_scope) { build(:granular_scope, boundary: Authz::Boundary.for(other_group)) }
  let(:instance_scope) { build(:granular_scope, boundary: Authz::Boundary.for(:instance)) }
  let(:other_instance_scope) { build(:granular_scope, boundary: Authz::Boundary.for(:instance)) }
  let(:user_scope) { build(:granular_scope, boundary: Authz::Boundary.for(:user)) }
  let(:all_memberships_scope) { build(:granular_scope, boundary: Authz::Boundary.for(:all_memberships)) }

  describe '.key_for' do
    it 'keys a namespaced scope by access level and namespace' do
      expect(described_class.key_for(group_scope)).to eq(['selected_memberships', group.id])
    end

    it 'keys a standalone scope by access level alone' do
      expect(described_class.key_for(instance_scope)).to eq(['instance', nil])
    end
  end

  describe '#first_duplicate' do
    subject(:first_duplicate) { described_class.new(new_scopes, existing_scopes: existing_scopes).first_duplicate }

    let(:existing_scopes) { [] }

    context 'when there are no new scopes' do
      let(:new_scopes) { [] }

      it { is_expected.to be_nil }
    end

    context 'when the new scopes target distinct boundaries' do
      let(:new_scopes) { [group_scope, other_group_scope, instance_scope] }

      it { is_expected.to be_nil }
    end

    context 'when the new scopes hold one scope per standalone access level' do
      let(:new_scopes) { [user_scope, instance_scope, all_memberships_scope] }

      it { is_expected.to be_nil }
    end

    context 'when the new scopes target the same namespace twice' do
      let(:new_scopes) { [group_scope, other_group_scope, same_group_scope] }

      it 'returns the later scope' do
        expect(first_duplicate).to be(same_group_scope)
      end
    end

    context 'when the new scopes hold the same standalone access level twice' do
      let(:new_scopes) { [instance_scope, other_instance_scope] }

      it 'returns the later scope' do
        expect(first_duplicate).to be(other_instance_scope)
      end
    end

    context 'when a new scope collides with an existing scope' do
      let(:existing_scopes) { [group_scope, instance_scope] }
      let(:new_scopes) { [other_group_scope, same_group_scope, other_instance_scope] }

      it 'returns the first colliding new scope and never an existing one' do
        expect(first_duplicate).to be(same_group_scope)
      end
    end

    context 'when a new standalone scope has a different access level from an existing one' do
      let(:existing_scopes) { [instance_scope] }
      let(:new_scopes) { [user_scope] }

      it { is_expected.to be_nil }
    end

    context 'when the existing scopes are a relation' do
      let_it_be(:token) do
        create(:granular_pat, boundary: Authz::Boundary.for(group), permissions: [:create_member_role])
      end

      let(:existing_scopes) { token.granular_scopes }

      context 'and a new scope targets the same namespace' do
        let(:new_scopes) { [same_group_scope] }

        it { is_expected.to be(same_group_scope) }
      end

      context 'and the new scopes target other boundaries' do
        let(:new_scopes) { [other_group_scope, instance_scope] }

        it { is_expected.to be_nil }
      end
    end
  end
end
