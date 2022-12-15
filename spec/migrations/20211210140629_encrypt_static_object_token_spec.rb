# frozen_string_literal: true
require 'spec_helper'

require_migration!

RSpec.describe EncryptStaticObjectToken, :migration, feature_category: :source_code_management do
  let!(:background_migration_jobs) { table(:background_migration_jobs) }
  let!(:users) { table(:users) }

  let!(:user_without_tokens) { create_user!(name: 'notoken') }
  let!(:user_with_plaintext_token_1) { create_user!(name: 'plaintext_1', token: 'token') }
  let!(:user_with_plaintext_token_2) { create_user!(name: 'plaintext_2', token: 'TOKEN') }
  let!(:user_with_encrypted_token) { create_user!(name: 'encrypted', encrypted_token: 'encrypted') }
  let!(:user_with_both_tokens) { create_user!(name: 'both', token: 'token2', encrypted_token: 'encrypted2') }

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migrations' do
    migrate!

    expect(background_migration_jobs.count).to eq(2)
    expect(background_migration_jobs.first.arguments).to match_array([user_with_plaintext_token_1.id, user_with_plaintext_token_1.id])
    expect(background_migration_jobs.second.arguments).to match_array([user_with_plaintext_token_2.id, user_with_plaintext_token_2.id])

    expect(BackgroundMigrationWorker.jobs.size).to eq(2)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, user_with_plaintext_token_1.id, user_with_plaintext_token_1.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, user_with_plaintext_token_2.id, user_with_plaintext_token_2.id)
  end

  private

  def create_user!(name:, token: nil, encrypted_token: nil)
    email = "#{name}@example.com"

    table(:users).create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      static_object_token: token,
      static_object_token_encrypted: encrypted_token
    )
  end
end
