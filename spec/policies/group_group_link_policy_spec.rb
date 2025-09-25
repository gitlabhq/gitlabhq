# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupGroupLinkPolicy, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group2) { create(:group, :private) }

  let(:group_group_link) do
    create(:group_group_link, shared_group: group, shared_with_group: group2)
  end

  subject(:policy) { described_class.new(user, group_group_link) }

  describe 'delegates to group policy' do
    context 'when user is group owner' do
      before_all do
        group.add_owner(user)
      end

      it 'allows update_group_link' do
        expect(policy).to be_allowed(:update_group_link)
      end

      it 'allows delete_group_link' do
        expect(policy).to be_allowed(:delete_group_link)
      end

      it 'allows create_group_link' do
        expect(policy).to be_allowed(:create_group_link)
      end
    end

    context 'when user is group maintainer' do
      before_all do
        group.add_maintainer(user)
      end

      it 'does not allow update_group_link' do
        expect(policy).to be_disallowed(:update_group_link)
      end

      it 'does not allow delete_group_link' do
        expect(policy).to be_disallowed(:delete_group_link)
      end

      it 'does not allow create_group_link' do
        expect(policy).to be_disallowed(:create_group_link)
      end
    end

    context 'when user has no group access' do
      it 'does not allow any group link permissions' do
        expect(policy).to be_disallowed(:update_group_link)
        expect(policy).to be_disallowed(:delete_group_link)
        expect(policy).to be_disallowed(:create_group_link)
      end
    end
  end
end
