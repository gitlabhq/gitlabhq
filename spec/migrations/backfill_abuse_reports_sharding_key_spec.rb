# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillAbuseReportsShardingKey, feature_category: :instance_resiliency do
  let(:connection) { ApplicationRecord.connection }
  let(:abuse_reports) { table(:abuse_reports) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:reporter) { create_user('reporter') }
  let!(:user1) { create_user('user1') }
  let!(:user2) { create_user('user2') }

  before do
    abuse_reports.create!(
      user_id: user1.id,
      reporter_id: reporter.id,
      organization_id: organization.id
    )

    report_without_org = abuse_reports.create!(
      user_id: user2.id,
      reporter_id: reporter.id,
      organization_id: organization.id
    )
    drop_constraint_and_trigger
    report_without_org.update_columns(organization_id: nil)
    recreate_trigger
  end

  after do
    recreate_constraint
  end

  it 'backfills abuse reports with nil organization_id' do
    expect(abuse_reports.where(organization_id: nil).count).to eq(1)
    expect(abuse_reports.where.not(organization_id: nil).count).to eq(1)

    expect { migrate! }.to change { abuse_reports.where(organization_id: nil).count }.by(-1)

    expect(abuse_reports.find_by(user_id: user1.id, reporter_id: reporter.id).organization_id)
      .to eq(organization.id)
    expect(abuse_reports.find_by(user_id: user2.id, reporter_id: reporter.id).organization_id)
      .to eq(organization.id)
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

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS trigger_f7464057d53e ON abuse_reports;

        ALTER TABLE abuse_reports DROP CONSTRAINT IF EXISTS check_1e642c5f94;
      SQL
    )
  end

  def recreate_constraint
    connection.execute(
      <<~SQL
        ALTER TABLE abuse_reports
          ADD CONSTRAINT check_1e642c5f94 CHECK ((organization_id IS NOT NULL));
      SQL
    )
  end

  def recreate_trigger
    connection.execute(
      <<~SQL
        CREATE TRIGGER trigger_f7464057d53e BEFORE INSERT OR UPDATE
          ON abuse_reports FOR EACH ROW EXECUTE FUNCTION trigger_f7464057d53e();
      SQL
    )
  end
end
