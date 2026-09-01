# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEmailsOrganizationId, feature_category: :user_profile do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:emails) { table(:emails) }

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
        start_id: emails.minimum(:id),
        end_id: emails.maximum(:id),
        batch_table: :emails,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    before do
      emails.create!(user_id: user1.id, email: 'user1-secondary@example.com', organization_id: organization1.id)
      emails.create!(user_id: user2.id, email: 'user2-secondary@example.com', organization_id: organization2.id)
      emails.create!(user_id: user1.id, email: 'user1-null@example.com', organization_id: nil)
      emails.create!(user_id: user2.id, email: 'user2-null@example.com', organization_id: nil)
    end

    it 'backfills organization_id for emails without one' do
      expect { migration.perform }.to change { emails.where(organization_id: nil).count }.from(2).to(0)
    end

    it 'sets organization_id from the associated user' do
      null_records = emails.where(organization_id: nil).to_a

      migration.perform

      null_records.each do |record|
        updated = emails.find(record.id)
        user = users.find(record.user_id)
        expect(updated.organization_id).to eq(user.organization_id)
      end
    end

    it 'does not modify emails that already have organization_id set' do
      existing_records = emails.where.not(organization_id: nil).pluck(:id, :organization_id).to_h

      migration.perform

      existing_records.each do |id, org_id|
        expect(emails.find(id).organization_id).to eq(org_id)
      end
    end

    it 'handles multiple organizations correctly' do
      migration.perform

      user1_emails = emails.where(user_id: user1.id)
      user2_emails = emails.where(user_id: user2.id)

      expect(user1_emails.pluck(:organization_id).uniq).to contain_exactly(organization1.id)
      expect(user2_emails.pluck(:organization_id).uniq).to contain_exactly(organization2.id)
    end
  end
end
