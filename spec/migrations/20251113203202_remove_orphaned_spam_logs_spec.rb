# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveOrphanedSpamLogs, feature_category: :insider_threat do
  let(:connection) { ApplicationRecord.connection }
  let(:spam_logs) { table(:spam_logs) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:constraint_name) { 'fk_1cb83308b1' }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:user) { create_user('user') }

  let!(:spam_log_with_valid_user) { create_spam_log(user.id) }
  let!(:spam_log_with_orphaned_user) { without_constraint { create_spam_log(users.maximum(:id).to_i + 1) } }

  describe '#up' do
    it 'removes orphaned spam_log records' do
      expect { migrate! }.to change { spam_logs.count }.from(2).to(1)

      expect(spam_logs.find_by(id: spam_log_with_valid_user.id)).not_to be_nil
      expect(spam_logs.find_by(id: spam_log_with_orphaned_user.id)).to be_nil
    end
  end

  describe '#down' do
    it 'is a no-op' do
      migrate!

      expect { schema_migrate_down! }.not_to change { spam_logs.count }
    end
  end

  private

  def create_user(username)
    users.create!(
      email: "#{username}@example.com",
      username: username,
      organization_id: organization.id,
      projects_limit: 10
    )
  end

  def create_spam_log(user_id)
    spam_logs.create!(user_id: user_id)
  end

  def drop_constraint
    connection.execute("ALTER TABLE spam_logs DROP CONSTRAINT IF EXISTS #{constraint_name}")
  end

  def recreate_constraint
    connection.execute(<<~SQL)
      ALTER TABLE spam_logs ADD CONSTRAINT #{constraint_name} FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT VALID
    SQL
  end

  def without_constraint
    drop_constraint
    yield
  ensure
    recreate_constraint
  end
end
