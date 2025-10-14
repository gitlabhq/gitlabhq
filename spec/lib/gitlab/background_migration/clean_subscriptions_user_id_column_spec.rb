# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CleanSubscriptionsUserIdColumn, feature_category: :team_planning do
  let(:subscriptions) { table(:subscriptions) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:user) do
    table(:users).create!(
      username: 'john_doe',
      email: 'johndoe@gitlab.com',
      projects_limit: 2,
      organization_id: organization.id
    )
  end

  let!(:valid_subscription1) { subscriptions.create!(user_id: user.id) }
  let!(:valid_subscription2) { subscriptions.create!(user_id: user.id) }

  let(:migration) do
    start_id, end_id = subscriptions.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :subscriptions,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  before do
    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE subscriptions DROP CONSTRAINT check_285574a00a;

      ALTER TABLE subscriptions DROP CONSTRAINT fk_933bdff476;
    SQL

    subscriptions.create!(user_id: nil)
    subscriptions.create!(user_id: nil)
    subscriptions.create!(user_id: non_existing_record_id)
    subscriptions.create!(user_id: non_existing_record_id)

    ApplicationRecord.connection.execute(<<~SQL)
      ALTER TABLE subscriptions
        ADD CONSTRAINT check_285574a00a CHECK ((user_id IS NOT NULL)) NOT VALID;

      ALTER TABLE ONLY subscriptions
        ADD CONSTRAINT fk_933bdff476 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT VALID;
    SQL
  end

  describe '#up' do
    subject(:migrate) { migration.perform }

    it 'updates records in batches' do
      expect do
        migrate
      end.to make_queries_matching(/DELETE FROM "subscriptions"/, 3)
    end

    it 'deletes invalid records' do
      expect do
        migrate
      end.to change { subscriptions.count }.from(6).to(2)

      expect(subscriptions.all).to contain_exactly(
        have_attributes(id: valid_subscription1.id),
        have_attributes(id: valid_subscription2.id)
      )
    end
  end
end
