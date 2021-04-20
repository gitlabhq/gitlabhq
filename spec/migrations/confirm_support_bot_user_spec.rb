# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ConfirmSupportBotUser, :migration do
  let(:users) { table(:users) }

  context 'when support bot user is currently unconfirmed' do
    let!(:support_bot) do
      create_user!(
        created_at: 2.days.ago,
        user_type: User::USER_TYPES['support_bot']
      )
    end

    it 'updates the `confirmed_at` attribute' do
      expect { migrate! }.to change { support_bot.reload.confirmed_at }
    end

    it 'sets `confirmed_at` to be the same as their `created_at` attribute' do
      migrate!

      expect(support_bot.reload.confirmed_at).to eq(support_bot.created_at)
    end
  end

  context 'when support bot user is already confirmed' do
    let!(:confirmed_support_bot) do
      create_user!(
        user_type: User::USER_TYPES['support_bot'],
        confirmed_at: 1.day.ago
      )
    end

    it 'does not change their `confirmed_at` attribute' do
      expect { migrate! }.not_to change { confirmed_support_bot.reload.confirmed_at }
    end
  end

  context 'when support bot user created_at is null' do
    let!(:support_bot) do
      create_user!(
        user_type: User::USER_TYPES['support_bot'],
        confirmed_at: nil,
        record_timestamps: false
      )
    end

    it 'updates the `confirmed_at` attribute' do
      expect { migrate! }.to change { support_bot.reload.confirmed_at }.from(nil)
    end

    it 'does not change the `created_at` attribute' do
      expect { migrate!}.not_to change { support_bot.reload.created_at }.from(nil)
    end
  end

  context 'with human users that are currently unconfirmed' do
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

  def create_user!(name: 'GitLab Support Bot', email: 'support@example.com', user_type:, created_at: Time.now, confirmed_at: nil, record_timestamps: true)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: confirmed_at,
      record_timestamps: record_timestamps
    )
  end
end
