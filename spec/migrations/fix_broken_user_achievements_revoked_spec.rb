# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixBrokenUserAchievementsRevoked, migration: :gitlab_main, feature_category: :user_profile do
  let(:migration) { described_class.new }

  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:achievements_table) { table(:achievements) }
  let(:user_achievements_table) { table(:user_achievements) }
  let(:namespace) { namespaces_table.create!(name: 'something', path: generate(:username)) }
  let(:achievement) { achievements_table.create!(name: 'something', namespace_id: namespace.id) }
  let(:user) { users_table.create!(username: generate(:username), projects_limit: 0) }
  let(:revoked_invalid) do
    user_achievements_table.create!(user_id: user.id, achievement_id: achievement.id, revoked_at: Time.current)
  end

  let(:revoked_valid) do
    user_achievements_table.create!(user_id: user.id, achievement_id: achievement.id, revoked_at: Time.current,
      revoked_by_user_id: user.id)
  end

  let(:not_revoked) { user_achievements_table.create!(user_id: user.id, achievement_id: achievement.id) }

  describe '#up' do
    it 'migrates the invalid user achievement' do
      expect { migrate! }
        .to change { revoked_invalid.reload.revoked_by_user_id }
        .from(nil).to(Users::Internal.ghost.id)
    end

    it 'does not migrate valid revoked user achievement' do
      expect { migrate! }
        .not_to change { revoked_valid.reload.revoked_by_user_id }
    end

    it 'does not migrate the not revoked user achievement' do
      expect { migrate! }
        .not_to change { not_revoked.reload.revoked_by_user_id }
    end
  end
end
