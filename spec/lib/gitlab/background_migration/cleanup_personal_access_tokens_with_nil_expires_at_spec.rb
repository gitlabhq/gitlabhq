# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanupPersonalAccessTokensWithNilExpiresAt, schema: 20230510062503, feature_category: :system_access do # rubocop:disable Layout/LineLength
  let(:personal_access_tokens_table) { table(:personal_access_tokens) }
  let(:users_table) { table(:users) }
  let(:expires_at_default) { described_class::EXPIRES_AT_DEFAULT }

  subject(:perform_migration) do
    described_class.new(
      start_id: 1,
      end_id: 30,
      batch_table: :personal_access_tokens,
      batch_column: :id,
      sub_batch_size: 3,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  before do
    user = users_table.create!(name: 'PAT_USER', email: 'pat_user@gmail.com', username: "pat_user1", projects_limit: 0)
    personal_access_tokens_table.create!(user_id: user.id, name: "PAT#1", expires_at: expires_at_default + 1.day)
    personal_access_tokens_table.create!(user_id: user.id, name: "PAT#2", expires_at: nil)
    personal_access_tokens_table.create!(user_id: user.id, name: "PAT#3", expires_at: Time.zone.now + 2.days)
  end

  it 'adds expiry to personal access tokens', :aggregate_failures do
    freeze_time do
      expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(3)

      expect(personal_access_tokens_table.find_by_name("PAT#1").expires_at).to eq(expires_at_default.to_date + 1.day)
      expect(personal_access_tokens_table.find_by_name("PAT#2").expires_at).to eq(expires_at_default.to_date)
      expect(personal_access_tokens_table.find_by_name("PAT#3").expires_at).to eq(Time.zone.now.to_date + 2.days)
    end
  end
end
