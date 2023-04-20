# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillAdminModeScopeForPersonalAccessTokens,
  :migration, schema: 20221228103133, feature_category: :system_access do
  let(:users) { table(:users) }
  let(:personal_access_tokens) { table(:personal_access_tokens) }

  let(:admin) { users.create!(name: 'admin', email: 'admin@example.com', projects_limit: 1, admin: true) }
  let(:user) { users.create!(name: 'user', email: 'user@example.com', projects_limit: 1) }

  let!(:pat_admin_1) { personal_access_tokens.create!(name: 'admin 1', user_id: admin.id, scopes: "---\n- api\n") }
  let!(:pat_user) { personal_access_tokens.create!(name: 'user 1', user_id: user.id, scopes: "---\n- api\n") }
  let!(:pat_revoked) do
    personal_access_tokens.create!(name: 'admin 2', user_id: admin.id, scopes: "---\n- api\n", revoked: true)
  end

  let!(:pat_expired) do
    personal_access_tokens.create!(name: 'admin 3', user_id: admin.id, scopes: "---\n- api\n", expires_at: 1.day.ago)
  end

  let!(:pat_admin_mode) do
    personal_access_tokens.create!(name: 'admin 4', user_id: admin.id, scopes: "---\n- admin_mode\n")
  end

  let!(:pat_with_symbol_in_scopes) do
    personal_access_tokens.create!(name: 'admin 5', user_id: admin.id, scopes: "---\n- :api\n")
  end

  let!(:pat_admin_2) { personal_access_tokens.create!(name: 'admin 6', user_id: admin.id, scopes: "---\n- read_api\n") }
  let!(:pat_not_in_range) { personal_access_tokens.create!(name: 'admin 7', user_id: admin.id, scopes: "---\n- api\n") }

  subject do
    described_class.new(
      start_id: pat_admin_1.id,
      end_id: pat_admin_2.id,
      batch_table: :personal_access_tokens,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  it "adds `admin_mode` scope to active personal access tokens of administrators" do
    subject.perform

    expect(pat_admin_1.reload.scopes).to eq("---\n- api\n- admin_mode\n")
    expect(pat_user.reload.scopes).to eq("---\n- api\n")
    expect(pat_revoked.reload.scopes).to eq("---\n- api\n")
    expect(pat_expired.reload.scopes).to eq("---\n- api\n")
    expect(pat_admin_mode.reload.scopes).to eq("---\n- admin_mode\n")
    expect(pat_with_symbol_in_scopes.reload.scopes).to eq("---\n- api\n- admin_mode\n")
    expect(pat_admin_2.reload.scopes).to eq("---\n- read_api\n- admin_mode\n")
    expect(pat_not_in_range.reload.scopes).to eq("---\n- api\n")
  end
end
