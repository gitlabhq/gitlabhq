# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserDetailsCompany, feature_category: :organization do
  let!(:organization) { table(:organizations).create!(path: 'some-org', name: 'some org') }
  let!(:users) { table(:users) }
  let!(:user_details) { table(:user_details) }

  let!(:user_with_both) do
    users.create!(name: 'bob', email: 'bob@example.com', projects_limit: 1,
      organization_id: organization.id).tap do |record|
      user_details.create!(user_id: record.id, organization: 'GitLab', company: 'GitLab')
    end
  end

  let!(:user_with_only_organization) do
    users.create!(name: 'alice', email: 'alice@example.com', projects_limit: 1,
      organization_id: organization.id).tap do |record|
      user_details.create!(user_id: record.id, organization: 'Acme Corp', company: '')
    end
  end

  let!(:user_with_empty_organization) do
    users.create!(name: 'charlie', email: 'charlie@example.com', projects_limit: 1,
      organization_id: organization.id).tap do |record|
      user_details.create!(user_id: record.id, organization: '', company: '')
    end
  end

  let(:migration) do
    described_class.new(
      start_id: user_details.minimum(:user_id),
      end_id: user_details.maximum(:user_id),
      batch_table: :user_details,
      batch_column: :user_id,
      sub_batch_size: 1_000,
      pause_ms: 2_000,
      connection: user_details.connection
    )
  end

  def migrate!
    migration.perform
  end

  def empty_company_user_ids
    user_details.where(company: '').order(:user_id).pluck(:user_id)
  end

  before do
    user_details.connection.execute("ALTER TABLE user_details DISABLE TRIGGER trigger_c48e4298f362")
    user_details.where(organization: 'Acme Corp').update_all(company: '')
    user_details.connection.execute("ALTER TABLE user_details ENABLE TRIGGER trigger_c48e4298f362")
  end

  describe '#up' do
    it 'backfills company records' do
      expected_before = [user_with_empty_organization.id, user_with_only_organization.id].sort
      expected_after = [user_with_empty_organization.id]

      expect { migrate! }.to change { empty_company_user_ids }.from(expected_before).to(expected_after)
    end
  end
end
