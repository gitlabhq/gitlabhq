require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180529152628_schedule_to_archive_legacy_traces')

describe ScheduleToArchiveLegacyTraces, :migration do
  include TraceHelpers

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
    @build_success = builds.create!(id: 1, project_id: 123, status: 'success', type: 'Ci::Build')
    @build_failed = builds.create!(id: 2, project_id: 123, status: 'failed', type: 'Ci::Build')
    @builds_canceled = builds.create!(id: 3, project_id: 123, status: 'canceled', type: 'Ci::Build')
    @build_running = builds.create!(id: 4, project_id: 123, status: 'running', type: 'Ci::Build')

    create_legacy_trace(@build_success, 'This job is done')
    create_legacy_trace(@build_failed, 'This job is done')
    create_legacy_trace(@builds_canceled, 'This job is done')
    create_legacy_trace(@build_running, 'This job is not done yet')
  end

  it 'correctly archive legacy traces' do
    expect(job_artifacts.count).to eq(0)
    expect(File.exist?(legacy_trace_path(@build_success))).to be_truthy
    expect(File.exist?(legacy_trace_path(@build_failed))).to be_truthy
    expect(File.exist?(legacy_trace_path(@builds_canceled))).to be_truthy
    expect(File.exist?(legacy_trace_path(@build_running))).to be_truthy

    migrate!

    expect(job_artifacts.count).to eq(3)
    expect(File.exist?(legacy_trace_path(@build_success))).to be_falsy
    expect(File.exist?(legacy_trace_path(@build_failed))).to be_falsy
    expect(File.exist?(legacy_trace_path(@builds_canceled))).to be_falsy
    expect(File.exist?(legacy_trace_path(@build_running))).to be_truthy
    expect(File.exist?(archived_trace_path(job_artifacts.where(job_id: @build_success.id).first))).to be_truthy
    expect(File.exist?(archived_trace_path(job_artifacts.where(job_id: @build_failed.id).first))).to be_truthy
    expect(File.exist?(archived_trace_path(job_artifacts.where(job_id: @builds_canceled.id).first))).to be_truthy
    expect(job_artifacts.where(job_id: @build_running.id)).not_to be_exist
  end
end
