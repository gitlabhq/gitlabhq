# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSpamLogsOrganizationId, feature_category: :instance_resiliency do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:spam_logs) { table(:spam_logs) }
  let(:constraint_name) { 'check_0c0873a24a' }

  let!(:default_organization) { organizations.create!(id: 1, name: 'default', path: 'default') }
  let!(:organization1) { organizations.create!(name: 'organization1', path: 'organization1') }
  let!(:organization2) { organizations.create!(name: 'organization2', path: 'organization2') }

  let!(:user1) do
    users.create!(
      email: 'user1@example.com',
      username: 'user1',
      projects_limit: 10,
      organization_id: organization1.id
    )
  end

  let!(:user2) do
    users.create!(
      email: 'user2@example.com',
      username: 'user2',
      projects_limit: 10,
      organization_id: organization2.id
    )
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: spam_logs.minimum(:id),
        end_id: spam_logs.maximum(:id),
        batch_table: :spam_logs,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    before do
      create_spam_log!(user: user1, organization_id: organization1.id)
      create_spam_log!(user: user2, organization_id: organization2.id)
      drop_constraint
      create_spam_log!(user: user1, organization_id: nil)
      create_spam_log!(user: user2, organization_id: nil)
    end

    after do
      recreate_constraint
    end

    it 'backfills organization_id for spam_logs without one' do
      expect { migration.perform }.to change { spam_logs.where(organization_id: nil).count }.from(2).to(0)
    end

    it 'sets organization_id from the associated user' do
      null_records = spam_logs.where(organization_id: nil).to_a

      migration.perform

      null_records.each do |record|
        updated = spam_logs.find(record.id)
        user = users.find(record.user_id)
        expect(updated.organization_id).to eq(user.organization_id)
      end
    end

    it 'does not modify spam_logs that already have organization_id' do
      existing_records = spam_logs.where.not(organization_id: nil).pluck(:id, :organization_id).to_h

      migration.perform

      existing_records.each do |id, org_id|
        expect(spam_logs.find(id).organization_id).to eq(org_id)
      end
    end
  end

  def create_spam_log!(user:, organization_id:)
    spam_logs.create!(
      user_id: user.id,
      organization_id: organization_id,
      source_ip: '127.0.0.1',
      noteable_type: 'Issue',
      title: 'Spam',
      created_at: Time.current,
      updated_at: Time.current
    )
  end

  def drop_constraint
    connection.execute(<<~SQL)
      ALTER TABLE spam_logs DROP CONSTRAINT IF EXISTS #{constraint_name};
    SQL
  end

  def recreate_constraint
    connection.execute(<<~SQL)
      ALTER TABLE spam_logs ADD CONSTRAINT #{constraint_name} CHECK ((organization_id IS NOT NULL)) NOT VALID;
    SQL
  end
end
