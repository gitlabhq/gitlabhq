# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::RemoteArtifacts, feature_category: :geo_replication do
  include_examples 'remote object storage cleaner' do
    let(:bucket_name) { 'artifacts' }
    let(:model_class) { ::Ci::JobArtifact }
    let(:stub_object_storage_uploader_for_cleaner) { stub_artifacts_object_storage }
    let(:model_with_file) { create(:ci_job_artifact, :remote_store, :zip) }
    let(:tracked_file_path) { model_with_file.file.path }
    let(:unknown_path_format_file_path) { 'foo/bar' }
    let(:untracked_valid_file_path) do
      prefix = "#{non_existing_project_hashed_path}/2025_04_23/"
      job_artifact_uploader_path = "#{non_existing_record_id}/#{non_existing_record_id}/ci_build_artifacts.zip"
      prefix + job_artifact_uploader_path
    end
  end

  describe '#find_tracked_paths' do
    let(:cleaner) { described_class.new }
    let(:artifact) { create(:ci_job_artifact, :remote_store, :zip) }
    let(:tracked_path) { artifact.file.path }
    let(:unknown_format_path) { 'invalid/path/format.zip' }

    # A legitimate path structure, but no matching row
    let(:untracked_path) { "#{tracked_path}.foo" }

    subject(:tracked_paths) { cleaner.send(:find_tracked_paths, file_paths) }

    before do
      stub_artifacts_object_storage
    end

    context 'with a tracked file' do
      let(:file_paths) { [tracked_path] }

      it { is_expected.to contain_exactly(tracked_path) }
    end

    context 'with an untracked file' do
      let(:file_paths) { [untracked_path] }

      it { is_expected.to be_empty }
    end

    context 'with a path in an unknown format' do
      let(:file_paths) { [unknown_format_path] }

      it 'reports it as tracked so that an unrecognized layout is never deleted' do
        expect(tracked_paths).to contain_exactly(unknown_format_path)
      end

      it 'does not query the database' do
        queries = ActiveRecord::QueryRecorder.new { tracked_paths }

        expect(queries.log.grep(/FROM "p_ci_job_artifacts"/)).to be_empty
      end
    end

    context 'with paths of known layouts that are not job artifacts' do
      let(:hash_path) { '4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce' }
      let(:pipeline_artifact_path) { "#{hash_path}/pipelines/1/artifacts/2/code_coverage.json" }
      let(:final_object_path) { "#{hash_path}/@final/c0/5a/e53e6eccd1a7fa8a6585f863cc6ea707edcd44a4cea913adcaea" }
      let(:file_paths) { [pipeline_artifact_path, final_object_path] }
      let(:logger) { instance_double(Logger, debug: nil, info: nil) }
      let(:cleaner) { described_class.new(logger: logger) }

      it 'reports them as tracked so that they are never deleted' do
        expect(tracked_paths).to contain_exactly(pipeline_artifact_path, final_object_path)
      end

      it 'does not log them as an unexpected format' do
        tracked_paths

        expect(logger).not_to have_received(:info).with(hash_including(message: /doesn't match the expected format/))
      end

      it 'logs each one with its layout' do
        tracked_paths

        expect(logger).to have_received(:debug).with(
          hash_including(file_path: pipeline_artifact_path, layout: :pipeline_artifact))
        expect(logger).to have_received(:debug).with(
          hash_including(file_path: final_object_path, layout: :final_object))
      end

      context 'when running the cleaner' do
        let(:remote_files) do
          file_paths.map { |path| instance_double(Fog::AWS::Storage::File, key: path) }
        end

        before do
          remote_directory = Struct.new(:files).new(files: remote_files)
          allow(cleaner).to receive(:remote_directory).and_return(remote_directory)
        end

        it 'logs a count per layout when the run ends' do
          cleaner.run!

          expect(logger).to have_received(:info).with(hash_including(layout: :pipeline_artifact, count: 1))
          expect(logger).to have_received(:info).with(hash_including(layout: :final_object, count: 1))
        end

        it 'never copies or destroys them' do
          remote_files.each do |file|
            expect(file).not_to receive(:copy)
            expect(file).not_to receive(:destroy)
          end

          cleaner.run!(dry_run: false)
        end
      end
    end

    context 'with a non-ASCII filename' do
      let(:file_paths) { [artifact.reload.file.path] }

      before do
        artifact.update_column(:file, 'tëst-ärtifact.zip')
      end

      it 'matches the row rather than reporting an orphan' do
        expect(tracked_paths).to eq(file_paths)
      end
    end

    context 'with a valid path behind an unexpected prefix' do
      let(:file_paths) { ["some-prefix/#{tracked_path}"] }

      it 'reports it as tracked rather than shifting the parsed values' do
        expect(tracked_paths).to eq(file_paths)
      end
    end

    context 'when two paths share the same tracking values' do
      # Same job_id, artifact_id and filename, but stored under a different date segment
      let(:duplicate_path) do
        path_parts = tracked_path.split('/')
        path_parts[3] = '2020_01_01'
        path_parts.join('/')
      end

      let(:file_paths) { [tracked_path, duplicate_path] }

      it 'reports both as tracked rather than dropping one' do
        expect(tracked_paths).to contain_exactly(tracked_path, duplicate_path)
      end
    end

    context 'with a mixed batch' do
      let(:other_artifact) { create(:ci_job_artifact, :remote_store, :zip) }
      let(:file_paths) { [tracked_path, untracked_path, unknown_format_path, other_artifact.file.path] }

      it 'returns only the tracked and unrecognized paths' do
        expect(tracked_paths).to contain_exactly(tracked_path, other_artifact.file.path, unknown_format_path)
      end

      it 'resolves the batch with a single query' do
        other_artifact # create before counting

        queries = ActiveRecord::QueryRecorder.new { tracked_paths }

        expect(queries.log.grep(/FROM "p_ci_job_artifacts"/).size).to eq(1)
      end
    end

    context 'when a path is tracked by a different artifact' do
      let(:other_artifact) { create(:ci_job_artifact, :remote_store, :zip) }

      # Reuses another artifact's ID, so the ID matches a row but the rest of the path does not
      let(:file_paths) do
        [tracked_path.sub(%r{/(\d+)/([^/]+)\z}) { "/#{other_artifact.id}/#{::Regexp.last_match(2)}" }]
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#expected_file_path_format_regexp' do
    let(:cleaner) { described_class.new }

    subject(:regexp) { cleaner.send(:expected_file_path_format_regexp) }

    it 'validates correct artifact file paths' do
      valid_path =
        '4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/2025_04_23/1/2/ci_build_artifacts.zip'
      expect(valid_path).to match(regexp)
    end

    it 'rejects invalid file paths' do
      invalid_path = 'invalid/path/format.zip'
      expect(invalid_path).not_to match(regexp)
    end

    it 'rejects an otherwise valid path behind a prefix' do
      prefixed_path =
        'x/4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/2025_04_23/1/2/build.zip'
      expect(prefixed_path).not_to match(regexp)
    end
  end
end
