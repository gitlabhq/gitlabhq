require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180529152628_archive_legacy_traces')

describe ArchiveLegacyTraces, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
    build = builds.create!(id: 1)

    @legacy_trace_path = File.join(
      Settings.gitlab_ci.builds_path,
      build.created_at.utc.strftime("%Y_%m"),
      build.project_id.to_s,
      "#{job.id}.log"
    )

    File.open(@legacy_trace_path, 'wb') { |stream| stream.write('aiueo') }
  end

  it 'correctly archive legacy traces' do
    expect(job_artifacts.count).to eq(0)
    expect(File.exist?(@legacy_trace_path)).to be_truthy

    migrate!

    expect(job_artifacts.count).to eq(1)
    expect(File.exist?(@legacy_trace_path)).to be_falsy
    expect(File.exist?(new_trace_path)).to be_truthy
  end

  def new_trace_path
    job_artifact = job_artifacts.first

    disk_hash = Digest::SHA2.hexdigest(job_artifact.project_id.to_s)
    creation_date = job_artifact.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
      creation_date, job_artifact.job_id.to_s, job_artifact.id.to_s)
  end
end
