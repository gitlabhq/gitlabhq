# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillAbuseEventsOrganizationId, feature_category: :instance_resiliency do
  let(:connection) { ApplicationRecord.connection }
  let(:abuse_reports) { table(:abuse_reports) }
  let(:abuse_events) { table(:abuse_events) }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:trigger_name) { 'trigger_ca93521f3a6d' }
  let(:constraint_name) { 'check_9b41e64a86' }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }
  let!(:reporter) { create_user('reporter') }
  let!(:user1) { create_user('user1') }
  let!(:user2) { create_user('user2') }

  let!(:abuse_report) do
    abuse_reports.create!(user_id: user1.id, reporter_id: reporter.id, organization_id: organization.id)
  end

  let!(:event_with_org) { create_event(user1, abuse_report, organization) }

  let!(:event_without_org) do
    drop_constraint_and_trigger
    create_event(user2, abuse_report, nil)
  end

  before do
    recreate_trigger
  end

  after do
    recreate_constraint
  end

  it 'backfills abuse events with nil organization_id' do
    expect(abuse_events.where(organization_id: nil).count).to eq(1)
    expect(abuse_events.where.not(organization_id: nil).count).to eq(1)

    expect { migrate! }.to change { abuse_events.where(organization_id: nil).count }.by(-1)

    expect(abuse_events.find_by(id: event_with_org.id).organization_id).to eq(organization.id)
    expect(abuse_events.find_by(id: event_without_org.id).organization_id).to eq(organization.id)
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

  def create_event(user, abuse_report, organization)
    abuse_events.create!(
      user_id: user.id,
      abuse_report_id: abuse_report.id,
      source: 0,
      organization_id: organization&.id
    )
  end

  def drop_constraint_and_trigger
    connection.execute(
      <<~SQL
        DROP TRIGGER IF EXISTS #{trigger_name} ON abuse_events;

        ALTER TABLE abuse_events DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL
    )
  end

  def recreate_constraint
    connection.execute(
      <<~SQL
        ALTER TABLE abuse_events ADD CONSTRAINT #{constraint_name} CHECK ((organization_id IS NOT NULL));
      SQL
    )
  end

  def recreate_trigger
    connection.execute(
      <<~SQL
        CREATE TRIGGER #{trigger_name} BEFORE INSERT OR UPDATE ON abuse_events FOR EACH ROW EXECUTE FUNCTION #{trigger_name}();
      SQL
    )
  end
end
