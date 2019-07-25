# frozen_string_literal: true

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
      create_legacy_trace(@build, 'trace in file')
    end

    it 'correctly archive legacy traces' do
      expect(job_artifacts.count).to eq(0)
      expect(File.exist?(legacy_trace_path(@build))).to be_truthy

      described_class.new.perform(1, 1)

      expect(job_artifacts.count).to eq(1)
      expect(File.exist?(legacy_trace_path(@build))).to be_falsy
      expect(File.read(archived_trace_path(job_artifacts.first))).to eq('trace in file')
    end
  end

  context 'when trace file does not exsits at the right place' do
    it 'does not raise errors nor create job artifact' do
      expect { described_class.new.perform(1, 1) }.not_to raise_error

      expect(job_artifacts.count).to eq(0)
    end
  end

  context 'when trace data exsits in database' do
    before do
      create_legacy_trace_in_db(@build, 'trace in db')
    end

    it 'correctly archive legacy traces' do
      expect(job_artifacts.count).to eq(0)
      expect(@build.read_attribute(:trace)).not_to be_empty

      described_class.new.perform(1, 1)

      @build.reload
      expect(job_artifacts.count).to eq(1)
      expect(@build.read_attribute(:trace)).to be_nil
      expect(File.read(archived_trace_path(job_artifacts.first))).to eq('trace in db')
    end
  end
end
