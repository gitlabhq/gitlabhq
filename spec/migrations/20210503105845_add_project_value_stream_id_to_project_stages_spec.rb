# frozen_string_literal: true

require 'spec_helper'

require_migration!('add_project_value_stream_id_to_project_stages')

RSpec.describe AddProjectValueStreamIdToProjectStages, schema: 20210503105022 do
  let(:stages) { table(:analytics_cycle_analytics_project_stages) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let(:namespace) { table(:namespaces).create!(name: 'ns1', path: 'nsq1') }

  before do
    project = projects.create!(name: 'p1', namespace_id: namespace.id)

    stages.create!(
      project_id: project.id,
      created_at: Time.now,
      updated_at: Time.now,
      start_event_identifier: 1,
      end_event_identifier: 2,
      name: 'stage 1'
    )

    stages.create!(
      project_id: project.id,
      created_at: Time.now,
      updated_at: Time.now,
      start_event_identifier: 3,
      end_event_identifier: 4,
      name: 'stage 2'
    )
  end

  it 'deletes the existing rows' do
    migrate!

    expect(stages.count).to eq(0)
  end
end
