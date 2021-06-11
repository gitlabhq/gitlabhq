# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ConfirmProjectBotUsers, :migration do
  let(:users) { table(:users) }

  context 'project bot users that are currently unconfirmed' do
    let!(:project_bot_1) do
      create_user!(
        name: 'bot_1',
        email: 'bot_1@example.com',
        created_at: 2.days.ago,
        user_type: described_class::User::USER_TYPE_PROJECT_BOT
      )
    end

    let!(:project_bot_2) do
      create_user!(
        name: 'bot_2',
        email: 'bot_2@example.com',
        created_at: 4.days.ago,
        user_type: described_class::User::USER_TYPE_PROJECT_BOT
      )
    end

    it 'updates their `confirmed_at` attribute' do
      expect { migrate! }
        .to change { project_bot_1.reload.confirmed_at }
        .and change { project_bot_2.reload.confirmed_at }
    end

    it 'sets `confirmed_at` to be the same as their `created_at` attribute' do
      migrate!

      [project_bot_1, project_bot_2].each do |bot|
        expect(bot.reload.confirmed_at).to eq(bot.created_at)
      end
    end
  end

  context 'project bot users that are currently confirmed' do
    let!(:confirmed_project_bot) do
      create_user!(
        name: 'bot_1',
        email: 'bot_1@example.com',
        user_type: described_class::User::USER_TYPE_PROJECT_BOT,
        confirmed_at: 1.day.ago
      )
    end

    it 'does not update their `confirmed_at` attribute' do
      expect { migrate! }.not_to change { confirmed_project_bot.reload.confirmed_at }
    end
  end

  context 'human users that are currently unconfirmed' do
    let!(:unconfirmed_human) do
      create_user!(
        name: 'human',
        email: 'human@example.com',
        user_type: nil
      )
    end

    it 'does not update their `confirmed_at` attribute' do
      expect { migrate! }.not_to change { unconfirmed_human.reload.confirmed_at }
    end
  end

  private

  def create_user!(name:, email:, user_type:, created_at: Time.now, confirmed_at: nil)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: confirmed_at
    )
  end
end
