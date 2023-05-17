# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateHumanUserType, schema: 20230327103401, feature_category: :user_management do # rubocop:disable Layout/LineLength
  let!(:valid_users) do
    # 13 is the max value we have at the moment.
    (0..13).map do |type|
      table(:users).create!(username: "user#{type}", email: "user#{type}@test.com", user_type: type, projects_limit: 0)
    end
  end

  let!(:user_to_update) do
    table(:users).create!(username: "user_nil", email: "user_nil@test.com", user_type: nil, projects_limit: 0)
  end

  let(:starting_id) { table(:users).pluck(:id).min }
  let(:end_id) { table(:users).pluck(:id).max }

  let(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection
    )
  end

  describe 'perform' do
    it 'updates user with `nil` user type only' do
      expect do
        migration.perform
        valid_users.map(&:reload)
        user_to_update.reload
      end.not_to change { valid_users.map(&:user_type) }

      expect(user_to_update.user_type).to eq(0)
    end
  end
end
