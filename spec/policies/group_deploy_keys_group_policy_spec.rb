# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployKeysGroupPolicy do
  subject { described_class.new(user, group_deploy_keys_group) }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group_deploy_key) { create(:group_deploy_key) }

  let(:group_deploy_keys_group) { create(:group_deploy_keys_group, group: group, group_deploy_key: group_deploy_key) }

  describe 'edit a group deploy key for a given group' do
    it 'is allowed when the user is an owner of this group' do
      group.add_owner(user)

      expect(subject).to be_allowed(:update_group_deploy_key_for_group)
    end

    it 'is not allowed when the user is not an owner of this group' do
      expect(subject).to be_disallowed(:update_group_deploy_key_for_group)
    end
  end
end
