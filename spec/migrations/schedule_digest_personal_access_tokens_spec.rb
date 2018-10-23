require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180913142237_schedule_digest_personal_access_tokens.rb')

describe ScheduleDigestPersonalAccessTokens, :migration, :sidekiq do
  let(:personal_access_tokens) { table(:personal_access_tokens) }
  let(:users) { table(:users) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 4)

    users.create(id: 1, email: 'user@example.com', projects_limit: 10)

    personal_access_tokens.create!(id: 1, user_id: 1, name: 'pat-01', token: 'token-01')
    personal_access_tokens.create!(id: 2, user_id: 1, name: 'pat-02', token: 'token-02')
    personal_access_tokens.create!(id: 3, user_id: 1, name: 'pat-03', token_digest: 'token_digest')
    personal_access_tokens.create!(id: 4, user_id: 1, name: 'pat-04', token: 'token-04')
    personal_access_tokens.create!(id: 5, user_id: 1, name: 'pat-05', token: 'token-05')
    personal_access_tokens.create!(id: 6, user_id: 1, name: 'pat-06', token: 'token-06')
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      migrate!

      expect(described_class::MIGRATION).to(
        be_scheduled_delayed_migration(
          5.minutes, 'PersonalAccessToken', 'token', 'token_digest', 1, 5))
      expect(described_class::MIGRATION).to(
        be_scheduled_delayed_migration(
          10.minutes, 'PersonalAccessToken', 'token', 'token_digest', 6, 6))
      expect(BackgroundMigrationWorker.jobs.size).to eq 2
    end
  end

  it 'schedules background migrations' do
    perform_enqueued_jobs do
      plain_text_token = 'token IS NOT NULL'

      expect(personal_access_tokens.where(plain_text_token).count).to eq 5

      migrate!

      expect(personal_access_tokens.where(plain_text_token).count).to eq 0
    end
  end
end
