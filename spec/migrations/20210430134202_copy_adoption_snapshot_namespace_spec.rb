# frozen_string_literal: true
#
require 'spec_helper'

require_migration!('copy_adoption_snapshot_namespace')

RSpec.describe CopyAdoptionSnapshotNamespace, :migration, schema: 20210430124630 do
  let(:namespaces_table) { table(:namespaces) }
  let(:segments_table) { table(:analytics_devops_adoption_segments) }
  let(:snapshots_table) { table(:analytics_devops_adoption_snapshots) }

  it 'updates all snapshots without namespace set' do
    namespaces_table.create!(id: 123, name: 'group1', path: 'group1')
    namespaces_table.create!(id: 124, name: 'group2', path: 'group2')

    segments_table.create!(id: 1, namespace_id: 123)
    segments_table.create!(id: 2, namespace_id: 124)

    create_snapshot(id: 1, segment_id: 1)
    create_snapshot(id: 2, segment_id: 2)
    create_snapshot(id: 3, segment_id: 2, namespace_id: 123)

    migrate!

    expect(snapshots_table.find(1).namespace_id).to eq 123
    expect(snapshots_table.find(2).namespace_id).to eq 124
    expect(snapshots_table.find(3).namespace_id).to eq 123
  end

  def create_snapshot(**additional_params)
    defaults = {
      recorded_at: Time.zone.now,
      issue_opened: true,
      merge_request_opened: true,
      merge_request_approved: true,
      runner_configured: true,
      pipeline_succeeded: true,
      deploy_succeeded: true,
      security_scan_succeeded: true,
      end_time: Time.zone.now.end_of_month
    }

    snapshots_table.create!(defaults.merge(additional_params))
  end
end
