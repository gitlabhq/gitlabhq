# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ConfirmSecurityBot, :migration, feature_category: :user_profile do
  let(:users) { table(:users) }

  let(:user_type) { 8 }

  context 'when bot is not created' do
    it 'skips migration' do
      migrate!

      bot = users.find_by(user_type: user_type)

      expect(bot).to be_nil
    end
  end

  context 'when bot is confirmed' do
    let(:bot) { table(:users).create!(user_type: user_type, confirmed_at: Time.current, projects_limit: 1) }

    it 'skips migration' do
      expect { migrate! }.not_to change { bot.reload.confirmed_at }
    end
  end

  context 'when bot is not confirmed' do
    let(:bot) { table(:users).create!(user_type: user_type, projects_limit: 1) }

    it 'update confirmed_at' do
      freeze_time do
        expect { migrate! }.to change { bot.reload.confirmed_at }.from(nil).to(Time.current)
      end
    end
  end
end
