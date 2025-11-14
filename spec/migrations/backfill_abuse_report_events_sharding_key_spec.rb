# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillAbuseReportEventsShardingKey, feature_category: :instance_resiliency do
  let(:connection) { ApplicationRecord.connection }
  let(:abuse_reports) { table(:abuse_reports) }
  let(:abuse_report_events) { table(:abuse_report_events) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:reporter) { create_user('reporter') }
  let!(:user) { create_user('user') }
  let!(:abuse_report) do
    abuse_reports.create!(
      user_id: user.id,
      reporter_id: reporter.id,
      organization_id: organization.id
    )
  end

  before do
    abuse_report_events.create!(
      abuse_report_id: abuse_report.id,
      user_id: user.id,
      organization_id: organization.id
    )

    event_without_org = abuse_report_events.create!(
      abuse_report_id: abuse_report.id,
      user_id: user.id,
      organization_id: organization.id
    )
    drop_constraint_and_trigger
    event_without_org.update_columns(organization_id: nil)
    recreate_trigger
  end

  after do
    recreate_constraint
  end

  it 'backfills abuse reports with nil organization_id' do
    expect(abuse_report_events.where(organization_id: nil).count).to eq(1)
    expect(abuse_report_events.where.not(organization_id: nil).count).to eq(1)

    expect { migrate! }.to change { abuse_report_events.where(organization_id: nil).count }.by(-1)

    expect(abuse_report_events.where(organization_id: nil).count).to eq(0)
    expect(abuse_report_events.where(organization_id: organization.id).count).to eq(2)
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
        DROP TRIGGER IF EXISTS trigger_1996c9e5bea0 ON abuse_report_events;

        ALTER TABLE abuse_report_events DROP CONSTRAINT IF EXISTS check_ed2aa0210e;
      SQL
    )
  end

  def recreate_constraint
    connection.execute(
      <<~SQL
        ALTER TABLE abuse_report_events
          ADD CONSTRAINT check_ed2aa0210e CHECK ((organization_id IS NOT NULL));
      SQL
    )
  end

  def recreate_trigger
    connection.execute(
      <<~SQL
        CREATE TRIGGER trigger_1996c9e5bea0 BEFORE INSERT OR UPDATE
          ON abuse_report_events FOR EACH ROW EXECUTE FUNCTION trigger_1996c9e5bea0();
      SQL
    )
  end
end
