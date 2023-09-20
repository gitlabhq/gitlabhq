# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateUsersSetExternalIfServiceAccount, feature_category: :system_access do
  describe "#perform" do
    let(:users_table) { table(:users) }
    let(:service_account_user) do
      users_table.create!(username: 'john_doe', email: 'johndoe@gitlab.com',
        user_type: HasUserType::USER_TYPES[:service_account], projects_limit: 5)
    end

    let(:service_user) do
      users_table.create!(username: 'john_doe2', email: 'johndoe2@gitlab.com',
        user_type: HasUserType::USER_TYPES[:service_user], projects_limit: 5)
    end

    let(:table_name) { :users }
    let(:batch_column) { :id }
    let(:sub_batch_size) { 2 }
    let(:pause_ms) { 0 }
    let(:migration) do
      described_class.new(
        start_id: service_account_user.id, end_id: service_user.id,
        batch_table: table_name, batch_column: batch_column,
        sub_batch_size: sub_batch_size, pause_ms: pause_ms,
        connection: ApplicationRecord.connection
      )
    end

    subject(:perform_migration) do
      migration.perform
    end

    it "changes external field for service_account user" do
      perform_migration

      expect(service_account_user.reload.external).to eq(true)
      expect(service_user.reload.external).to eq(false)
    end
  end
end
