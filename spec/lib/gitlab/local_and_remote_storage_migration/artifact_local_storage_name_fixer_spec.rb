# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LocalAndRemoteStorageMigration::ArtifactLocalStorageNameFixer, feature_category: :job_artifacts do
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:fixer) { described_class.new(logger) }
  let(:artifact_class) { class_double(Ci::JobArtifact) }

  before do
    stub_const('Ci::JobArtifact', artifact_class)
  end

  describe '#rename_artifacts' do
    let(:artifact1) do
      instance_double(Ci::JobArtifact, id: 1, size: 123, class: class_double(Ci::JobArtifact, name: 'Ci::JobArtifact'))
    end

    let(:artifact2) do
      instance_double(Ci::JobArtifact, id: 2, size: 456, class: class_double(Ci::JobArtifact, name: 'Ci::JobArtifact'))
    end

    let(:batch_relation_class) do
      Class.new do
        include EachBatch
      end
    end

    let(:batch_relation) { class_double(batch_relation_class, each_batch: nil) }

    before do
      allow(artifact_class).to receive(:with_files_stored_locally).and_return(batch_relation)
      allow(batch_relation).to receive(:each_batch).and_yield([artifact1, artifact2])
    end

    it 'logs start message' do
      expect(logger).to receive(:info).with('Starting renaming process in local storage')
      allow(Gitlab::LocalAndRemoteStorageMigration::FilePathFixer).to receive(:fix_file_path!).and_return(true)

      fixer.rename_artifacts
    end

    it 'calls FilePathFixer for each artifact' do
      expect(Gitlab::LocalAndRemoteStorageMigration::FilePathFixer)
        .to receive(:fix_file_path!).with(artifact1).and_return(true)
      expect(Gitlab::LocalAndRemoteStorageMigration::FilePathFixer)
        .to receive(:fix_file_path!).with(artifact2).and_return(true)

      fixer.rename_artifacts
    end

    it 'logs successful renames' do
      allow(Gitlab::LocalAndRemoteStorageMigration::FilePathFixer)
        .to receive(:fix_file_path!).and_return(true)

      expect(logger).to receive(:info).with('Starting renaming process in local storage')
      expect(logger).to receive(:info).with('Renamed Ci::JobArtifact ID 1 with size 123.')
      expect(logger).to receive(:info).with('Renamed Ci::JobArtifact ID 2 with size 456.')

      fixer.rename_artifacts
    end

    it 'logs warnings on errors' do
      allow(Gitlab::LocalAndRemoteStorageMigration::FilePathFixer)
        .to receive(:fix_file_path!).and_raise(IOError, 'boom')

      expect(logger).to receive(:warn).with('Failed to rename Ci::JobArtifact ID 1 with error: boom.')
      expect(logger).to receive(:warn).with('Failed to rename Ci::JobArtifact ID 2 with error: boom.')

      fixer.rename_artifacts
    end
  end

  describe '#batch_size' do
    it 'returns default value of 10' do
      expect(fixer.send(:batch_size)).to eq(10)
    end

    it 'returns custom value from ENV' do
      stub_env('MIGRATION_BATCH_SIZE', '50')
      expect(fixer.send(:batch_size)).to eq(50)
    end
  end
end
