require 'spec_helper'

describe Gitlab::BackgroundMigration::ArchiveLegacyTraces, :migration, schema: 20180529152628 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
    build = builds.create!(id: 1, project_id: 123, status: 'success')

    @legacy_trace_dir = File.join(Settings.gitlab_ci.builds_path,
      build.created_at.utc.strftime("%Y_%m"),
      build.project_id.to_s)
    
    FileUtils.mkdir_p(@legacy_trace_dir)

    @legacy_trace_path = File.join(@legacy_trace_dir, "#{build.id}.log")
  end

  context 'when trace file exsits at the right place' do
    before do
      File.open(@legacy_trace_path, 'wb') { |stream| stream.write('aiueo') }
    end

    it 'correctly archive legacy traces' do
      expect(job_artifacts.count).to eq(0)
      expect(File.exist?(@legacy_trace_path)).to be_truthy

      described_class.new.perform(1, 1)

      expect(job_artifacts.count).to eq(1)
      expect(File.exist?(@legacy_trace_path)).to be_falsy
      expect(File.read(new_trace_path)).to eq('aiueo')
    end
  end

  context 'when trace file does not exsits at the right place' do
    it 'correctly archive legacy traces' do
      expect(job_artifacts.count).to eq(0)
      expect(File.exist?(@legacy_trace_path)).to be_falsy

      described_class.new.perform(1, 1)

      expect(job_artifacts.count).to eq(0)
    end
  end

  def new_trace_path
    job_artifact = job_artifacts.first

    disk_hash = Digest::SHA2.hexdigest(job_artifact.project_id.to_s)
    creation_date = job_artifact.created_at.utc.strftime('%Y_%m_%d')

    File.join(Gitlab.config.artifacts.path, disk_hash[0..1], disk_hash[2..3], disk_hash,
      creation_date, job_artifact.job_id.to_s, job_artifact.id.to_s, 'job.log')
  end
end
