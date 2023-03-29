# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::NullifyLastErrorFromProjectMirrorData, feature_category: :source_code_management do # rubocop:disable Layout/LineLength
  it 'nullifies last_error column on all rows' do
    namespaces = table(:namespaces)
    projects = table(:projects)
    project_import_states = table(:project_mirror_data)

    group = namespaces.create!(name: 'gitlab', path: 'gitlab-org')

    project_namespace_1 = namespaces.create!(name: 'gitlab', path: 'gitlab-org')
    project_namespace_2 = namespaces.create!(name: 'gitlab', path: 'gitlab-org')
    project_namespace_3 = namespaces.create!(name: 'gitlab', path: 'gitlab-org')

    project_1 = projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace_1.id,
      name: 'test1'
    )
    project_2 = projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace_2.id,
      name: 'test2'
    )
    project_3 = projects.create!(
      namespace_id: group.id,
      project_namespace_id: project_namespace_3.id,
      name: 'test3'
    )

    project_import_state_1 = project_import_states.create!(
      project_id: project_1.id,
      status: 0,
      last_update_started_at: 1.hour.ago,
      last_update_scheduled_at: 1.hour.ago,
      last_update_at: 1.hour.ago,
      last_successful_update_at: 2.days.ago,
      last_error: '13:fetch remote: "fatal: unable to look up user:pass@gitlab.com (port 9418) (nodename nor servname provided, or not known)\n": exit status 128.', # rubocop:disable Layout/LineLength
      correlation_id_value: SecureRandom.uuid,
      jid: SecureRandom.uuid
    )

    project_import_states.create!(
      project_id: project_2.id,
      status: 1,
      last_update_started_at: 1.hour.ago,
      last_update_scheduled_at: 1.hour.ago,
      last_update_at: 1.hour.ago,
      last_successful_update_at: nil,
      next_execution_timestamp: 1.day.from_now,
      last_error: '',
      correlation_id_value: SecureRandom.uuid,
      jid: SecureRandom.uuid
    )

    project_import_state_3 = project_import_states.create!(
      project_id: project_3.id,
      status: 2,
      last_update_started_at: 1.hour.ago,
      last_update_scheduled_at: 1.hour.ago,
      last_update_at: 1.hour.ago,
      last_successful_update_at: 1.hour.ago,
      next_execution_timestamp: 1.day.from_now,
      last_error: nil,
      correlation_id_value: SecureRandom.uuid,
      jid: SecureRandom.uuid
    )

    migration = described_class.new(
      start_id: project_import_state_1.id,
      end_id: project_import_state_3.id,
      batch_table: :project_mirror_data,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )

    w_last_error_count = -> { project_import_states.where.not(last_error: nil).count } # rubocop:disable CodeReuse/ActiveRecord
    expect { migration.perform }.to change(&w_last_error_count).from(2).to(0)
  end
end
