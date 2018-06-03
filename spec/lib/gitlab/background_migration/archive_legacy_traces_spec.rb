require 'spec_helper'

describe Gitlab::BackgroundMigration::ArchiveLegacyTraces, :migration, schema: 20180529152628 do
  include TraceHelpers

  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  before do
    namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
    @build = builds.create!(id: 1, project_id: 123, status: 'success', type: 'Ci::Build')
  end

  context 'when trace file exsits at the right place' do
    before do
      create_legacy_trace(@build, 'aiueo')
    end

    it 'correctly archive legacy traces' do
      expect(job_artifacts.count).to eq(0)
      expect(File.exist?(legacy_trace_path(@build))).to be_truthy

      described_class.new.perform(1, 1)

      expect(job_artifacts.count).to eq(1)
      expect(File.exist?(legacy_trace_path(@build))).to be_falsy
      expect(File.read(archived_trace_path(job_artifacts.first))).to eq('aiueo')
    end
  end

  context 'when trace file does not exsits at the right place' do
    it 'does not raise errors and create job artifact row' do
      described_class.new.perform(1, 1)

      expect(job_artifacts.count).to eq(0)
    end
  end
end
