# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixProjectDailyStatisticsSyncTrigger, feature_category: :source_code_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let!(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let!(:namespace) { namespaces.create!(name: 'test', path: 'test', organization_id: organization.id) }
  let!(:project) do
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let(:daily_statistics) { table(:project_daily_statistics) }
  let(:archived_statistics) { table(:project_daily_statistics_archived) }

  describe '#up' do
    it 'adds ON CONFLICT DO NOTHING to the trigger INSERT branch' do
      migrate!

      function_def = ApplicationRecord.connection.execute(<<~SQL).first['prosrc']
        SELECT prosrc FROM pg_proc WHERE proname = 'table_sync_function_c237afdf68'
      SQL

      expect(function_def).to include('ON CONFLICT ("project_id", "date") DO NOTHING')
    end

    it 'does not raise error when inserting duplicate into archived table' do
      archived_statistics.create!(id: 1, project_id: project.id, fetch_count: 1, date: Time.zone.today)

      migrate!

      expect do
        daily_statistics.create!(project_id: project.id, fetch_count: 0, date: Time.zone.today)
      end.not_to raise_error
    end

    it 'still syncs new rows to archived table' do
      migrate!

      daily_statistics.create!(project_id: project.id, fetch_count: 0, date: Time.zone.today)

      expect(archived_statistics.find_by(project_id: project.id, date: Time.zone.today)).to be_present
    end
  end

  describe '#down' do
    it 'restores the original trigger without ON CONFLICT' do
      migrate!
      schema_migrate_down!

      function_def = ApplicationRecord.connection.execute(<<~SQL).first['prosrc']
        SELECT prosrc FROM pg_proc WHERE proname = 'table_sync_function_c237afdf68'
      SQL

      expect(function_def).not_to include('ON CONFLICT DO NOTHING')
    end
  end
end
