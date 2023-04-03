# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDeactivatedUserHighestRoleStats, feature_category: :seat_cost_management do
  let!(:users) { table(:users) }
  let!(:user_highest_roles) { table(:user_highest_roles) }

  let!(:user1) do
    users.create!(username: 'user1', email: 'user1@example.com', projects_limit: 10, state: 'active')
  end

  let!(:user2) do
    users.create!(username: 'user2', email: 'user2@example.com', projects_limit: 10, state: 'deactivated')
  end

  let!(:highest_role1) { user_highest_roles.create!(user_id: user1.id) }
  let!(:highest_role2) { user_highest_roles.create!(user_id: user2.id) }

  describe '#up' do
    context 'when on gitlab.com' do
      it 'does not change user highest role records' do
        allow(Gitlab).to receive(:com?).and_return(true)
        expect { migrate! }.not_to change(user_highest_roles, :count)
      end
    end

    context 'when not on gitlab.com' do
      it 'removes all user highest role records for deactivated users' do
        allow(Gitlab).to receive(:com?).and_return(false)
        migrate!
        expect(user_highest_roles.pluck(:user_id)).to contain_exactly(
          user1.id
        )
      end
    end
  end
end
