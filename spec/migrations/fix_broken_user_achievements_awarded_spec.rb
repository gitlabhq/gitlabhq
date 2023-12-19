# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixBrokenUserAchievementsAwarded, migration: :gitlab_main, feature_category: :user_profile do
  let(:migration) { described_class.new }

  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:achievements_table) { table(:achievements) }
  let(:user_achievements_table) { table(:user_achievements) }
  let(:namespace) { namespaces_table.create!(name: 'something', path: generate(:username)) }
  let(:achievement) { achievements_table.create!(name: 'something', namespace_id: namespace.id) }
  let(:user) { users_table.create!(username: generate(:username), projects_limit: 0) }
  let(:awarding_user) do
    users_table.create!(username: generate(:username), email: generate(:email), projects_limit: 0)
  end

  let!(:user_achievement_invalid) do
    user_achievements_table.create!(user_id: user.id, achievement_id: achievement.id,
      awarded_by_user_id: awarding_user.id)
  end

  let!(:user_achievement_valid) do
    user_achievements_table.create!(user_id: user.id, achievement_id: achievement.id,
      awarded_by_user_id: user.id)
  end

  describe '#up' do
    before do
      awarding_user.delete
    end

    it 'migrates the invalid user achievement' do
      expect { migrate! }
        .to change { user_achievement_invalid.reload.awarded_by_user_id }
        .from(nil).to(Users::Internal.ghost.id)
    end

    it 'does not migrate the valid user achievement' do
      expect { migrate! }
        .not_to change { user_achievement_valid.reload.awarded_by_user_id }
    end
  end
end
