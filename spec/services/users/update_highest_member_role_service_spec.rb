# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateHighestMemberRoleService, feature_category: :user_management do
  let(:user) { create(:user) }
  let(:execute_service) { described_class.new(user).execute }

  describe '#execute' do
    context 'when user_highest_role already exists' do
      let!(:user_highest_role) { create(:user_highest_role, :guest, user: user) }

      context 'when the current highest access level equals the already stored highest access level' do
        it 'does not update the highest access level' do
          create(:group_member, :guest, user: user)

          expect { execute_service }.not_to change { user_highest_role.reload.highest_access_level }
        end
      end

      context 'when the current highest access level does not equal the already stored highest access level' do
        it 'updates the highest access level' do
          create(:group_member, :developer, user: user)

          expect { execute_service }
            .to change { user_highest_role.reload.highest_access_level }
            .from(Gitlab::Access::GUEST)
            .to(Gitlab::Access::DEVELOPER)
        end
      end
    end

    context 'when user_highest_role does not exist' do
      it 'creates an user_highest_role object to store the highest access level' do
        create(:group_member, :guest, user: user)

        expect { execute_service }.to change { UserHighestRole.count }.from(0).to(1)
      end
    end
  end
end
