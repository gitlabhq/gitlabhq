# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SetInternalBotsToHavePrivateProfiles, feature_category: :user_profile do
  let(:users) { table(:users) }
  let(:time) { 1.year.ago }
  let(:user_types) do
    {
      support_bot: 1,
      alert_bot: 2,
      visual_review_bot: 3,
      migration_bot: 7,
      security_bot: 8,
      automation_bot: 9,
      admin_bot: 11,
      suggested_reviewers_bot: 12,
      llm_bot: 14,
      duo_code_review_bot: 16
    }
  end

  let!(:alert_bot) do
    users.create!(
      user_type: user_types[:alert_bot],
      projects_limit: 0,
      name: 'alert bot',
      email: 'alert-bot@example.com')
  end

  let!(:migration_bot) do
    users.create!(
      user_type: user_types[:migration_bot],
      projects_limit: 0,
      name: 'migration bot',
      email: 'migration-bot@example.com',
      confirmed_at: time)
  end

  let!(:security_bot) do
    users.create!(
      user_type: user_types[:security_bot],
      projects_limit: 0,
      name: 'security bot',
      email: 'security-bot@example.com',
      confirmed_at: time)
  end

  let!(:support_bot) do
    users.create!(
      user_type: user_types[:support_bot],
      projects_limit: 0,
      name: 'support bot',
      email: 'support-bot@example.com',
      confirmed_at: time)
  end

  let!(:automation_bot) do
    users.create!(
      user_type: user_types[:automation_bot],
      projects_limit: 0,
      name: 'automation bot',
      email: 'automation-bot@example.com')
  end

  let!(:llm_bot) do
    users.create!(
      user_type: user_types[:llm_bot],
      projects_limit: 0,
      name: 'llm bot',
      email: 'llm-bot@example.com',
      confirmed_at: time,
      private_profile: true)
  end

  let!(:duo_code_review_bot) do
    users.create!(
      user_type: user_types[:duo_code_review_bot],
      projects_limit: 0,
      name: 'duo code review bot',
      email: 'duo-code-review-bot@example.com',
      confirmed_at: time
    )
  end

  let!(:admin_bot) do
    users.create!(
      user_type: user_types[:admin_bot],
      projects_limit: 0,
      name: 'admin bot',
      email: 'admin-bot@example.com',
      confirmed_at: time)
  end

  let!(:visual_review_bot) do
    users.create!(
      user_type: user_types[:visual_review_bot],
      projects_limit: 0,
      name: 'visual review bot',
      email: 'visual-review-bot@example.com')
  end

  let!(:suggested_reviewers_bot) do
    users.create!(
      user_type: user_types[:suggested_reviewers_bot],
      projects_limit: 0,
      name: 'suggested reviewers bot',
      email: 'suggested-reviewers-bot@example.com')
  end

  describe "#up" do
    it 'sets confirmed_at and private_profile for all internal bots' do
      migrate!

      bot_users = users.where(user_type: user_types.values)

      expect(bot_users.count).to be 10
      expect(bot_users.where(confirmed_at: nil, private_profile: false).count).to be 0
    end

    it 'does not update existing confirmed_at' do
      migrate!

      [
        migration_bot,
        security_bot,
        support_bot,
        llm_bot,
        duo_code_review_bot,
        admin_bot
      ].each do |user|
        expect(user.confirmed_at).to eq(time)
      end

      [
        alert_bot,
        automation_bot,
        visual_review_bot,
        suggested_reviewers_bot
      ].each do |user|
        expect(user.confirmed_at).not_to eq(time)
      end
    end
  end
end
