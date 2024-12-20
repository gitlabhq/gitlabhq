# frozen_string_literal: true

require 'spec_helper'

# Main user namespace functionality it still in `Namespace`, so most
# of the specs are in `namespace_spec.rb`.
# UserNamespace specific specs will end up being migrated here.
RSpec.describe Namespaces::UserNamespace, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:owner) }
  end

  describe 'owner methods' do
    let(:owner) { build(:user) }
    let(:namespace) { build(:namespace, owner: owner) }

    describe '#owners' do
      specify do
        expect(namespace.owners).to match_array([owner])
      end
    end
  end

  describe '#member?' do
    let_it_be(:namespace) { create(:user_namespace) }
    let_it_be(:other_user) { create(:user) }

    it 'returns true for owner' do
      expect(namespace.member?(namespace.owner)).to be_truthy
    end

    it 'returns true for admin' do
      allow(other_user).to receive(:can_admin_all_resources?).and_return(true)

      expect(namespace.member?(other_user)).to be_truthy
    end

    it 'returns false for other users' do
      expect(namespace.member?(other_user)).to be_falsey
    end
  end

  describe '#max_member_access_for_user' do
    let_it_be(:namespace) { create(:user_namespace) }

    context 'with user in the namespace' do
      it 'returns correct access level' do
        expect(namespace.max_member_access_for_user(namespace.owner)).to eq(Gitlab::Access::OWNER)
      end
    end

    context 'when user is nil' do
      it 'returns NO_ACCESS' do
        expect(namespace.max_member_access_for_user(nil)).to eq(Gitlab::Access::NO_ACCESS)
      end
    end

    context 'when evaluating admin access level' do
      let_it_be(:admin) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns OWNER by default' do
          expect(namespace.max_member_access_for_user(admin)).to eq(Gitlab::Access::OWNER)
        end
      end

      context 'when admin mode is disabled' do
        it 'returns NO_ACCESS' do
          expect(namespace.max_member_access_for_user(admin)).to eq(Gitlab::Access::NO_ACCESS)
        end
      end

      it 'returns NO_ACCESS when only concrete membership should be considered' do
        expect(namespace.max_member_access_for_user(admin, only_concrete_membership: true))
          .to eq(Gitlab::Access::NO_ACCESS)
      end
    end

    context 'when organization owner' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:group) { create(:group, organization: organization) }
      let_it_be(:org_owner) do
        create(:organization_owner, organization: organization).user
      end

      it 'returns OWNER by default' do
        expect(group.max_member_access_for_user(org_owner)).to eq(Gitlab::Access::OWNER)
      end

      context 'when organization owner is also an admin' do
        before do
          org_owner.update!(admin: true)
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'returns OWNER by default' do
            expect(group.max_member_access_for_user(org_owner)).to eq(Gitlab::Access::OWNER)
          end
        end

        context 'when admin mode is disabled' do
          it 'returns NO_ACCESS by default' do
            expect(group.max_member_access_for_user(org_owner)).to eq(Gitlab::Access::NO_ACCESS)
          end
        end
      end

      context 'when only concrete members' do
        it 'returns NO_ACCESS' do
          expect(group.max_member_access_for_user(org_owner, only_concrete_membership: true))
            .to eq(Gitlab::Access::NO_ACCESS)
        end
      end
    end
  end
end
