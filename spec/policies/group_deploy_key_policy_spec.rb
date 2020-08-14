# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployKeyPolicy do
  subject { described_class.new(user, group_deploy_key) }

  let_it_be(:user) { create(:user) }

  describe 'edit a group deploy key' do
    context 'when the user does not own the group deploy key' do
      let(:group_deploy_key) { create(:group_deploy_key) }

      it { is_expected.to be_disallowed(:update_group_deploy_key) }
    end

    context 'when the user owns the group deploy key' do
      let(:group_deploy_key) { create(:group_deploy_key, user: user) }

      before do
        user.reload
      end

      it { is_expected.to be_allowed(:update_group_deploy_key) }
    end
  end
end
