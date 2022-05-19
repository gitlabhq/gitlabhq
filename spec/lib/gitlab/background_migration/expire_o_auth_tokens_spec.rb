# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ExpireOAuthTokens, :migration, schema: 20220428133724 do
  let(:migration) { described_class.new }
  let(:oauth_access_tokens_table) { table(:oauth_access_tokens) }

  let(:table_name) { 'oauth_access_tokens' }

  subject(:perform_migration) do
    described_class.new(start_id: 1,
                        end_id: 30,
                        batch_table: :oauth_access_tokens,
                        batch_column: :id,
                        sub_batch_size: 2,
                        pause_ms: 0,
                        connection: ActiveRecord::Base.connection)
                   .perform
  end

  before do
    oauth_access_tokens_table.create!(id: 1, token: 's3cr3t-1', expires_in: nil)
    oauth_access_tokens_table.create!(id: 2, token: 's3cr3t-2', expires_in: 42)
    oauth_access_tokens_table.create!(id: 3, token: 's3cr3t-3', expires_in: nil)
  end

  it 'adds expiry to oauth tokens', :aggregate_failures do
    expect(ActiveRecord::QueryRecorder.new { perform_migration }.count).to eq(3)

    expect(oauth_access_tokens_table.find(1).expires_in).to eq(7_200)
    expect(oauth_access_tokens_table.find(2).expires_in).to eq(42)
    expect(oauth_access_tokens_table.find(3).expires_in).to eq(7_200)
  end
end
