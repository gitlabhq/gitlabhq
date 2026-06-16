# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillShowOnProfileForOptedOutUsers, migration: :gitlab_main_org,
  feature_category: :user_profile do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:user_preferences) { table(:user_preferences) }
  let(:achievements) { table(:achievements) }
  let(:user_achievements) { table(:user_achievements) }

  let(:organization) { organizations.create!(path: 'org') }

  let(:namespace) do
    namespaces.create!(
      name: 'test-namespace',
      path: 'test-namespace',
      organization_id: organization.id
    )
  end

  let(:opted_out_user) do
    users.create!(
      email: 'opted_out@example.com',
      username: 'opted_out_user',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:opted_in_user) do
    users.create!(
      email: 'opted_in@example.com',
      username: 'opted_in_user',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:no_preference_user) do
    users.create!(
      email: 'no_preference@example.com',
      username: 'no_preference_user',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:achievement) do
    achievements.create!(
      namespace_id: namespace.id,
      name: 'Test Achievement',
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  let!(:opted_out_user_achievement) do
    user_preferences.create!(user_id: opted_out_user.id, achievements_enabled: false)
    user_achievements.create!(
      achievement_id: achievement.id,
      user_id: opted_out_user.id,
      namespace_id: namespace.id,
      show_on_profile: true,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  let!(:opted_in_user_achievement) do
    user_preferences.create!(user_id: opted_in_user.id, achievements_enabled: true)
    user_achievements.create!(
      achievement_id: achievement.id,
      user_id: opted_in_user.id,
      namespace_id: namespace.id,
      show_on_profile: true,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  let!(:no_preference_user_achievement) do
    user_achievements.create!(
      achievement_id: achievement.id,
      user_id: no_preference_user.id,
      namespace_id: namespace.id,
      show_on_profile: true,
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  describe '#up' do
    it 'sets show_on_profile correctly for all user types', :aggregate_failures do
      migrate!

      expect(opted_out_user_achievement.reload.show_on_profile).to be false
      expect(opted_in_user_achievement.reload.show_on_profile).to be true
      expect(no_preference_user_achievement.reload.show_on_profile).to be true
    end
  end

  describe '#down' do
    it 'is a no-op' do
      migrate!

      expect { schema_migrate_down! }.not_to change {
        [
          opted_out_user_achievement.reload.show_on_profile,
          opted_in_user_achievement.reload.show_on_profile,
          no_preference_user_achievement.reload.show_on_profile
        ]
      }
    end
  end
end
