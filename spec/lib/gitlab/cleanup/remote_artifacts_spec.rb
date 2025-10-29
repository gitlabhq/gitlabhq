# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::RemoteArtifacts, feature_category: :geo_replication do
  include_examples 'remote object storage cleaner',
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/545622' do
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

  describe '#query_for_row_tracking_the_file' do
    let(:cleaner) { described_class.new }
    let(:artifact) { create(:ci_job_artifact, :remote_store, :zip) }

    before do
      stub_artifacts_object_storage
    end

    context 'with a tracked file' do
      let(:file_path) { artifact.file.path }

      it 'returns a relation that includes the artifact',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/545624' do
        query = cleaner.send(:query_for_row_tracking_the_file, file_path)

        expect(query.exists?).to be true
      end
    end

    context 'with an untracked file' do
      # A legitimate path structure but with a different filename
      let(:file_path) { "#{artifact.file.path}.foo" }

      it 'returns a relation that does not find any artifact' do
        query = cleaner.send(:query_for_row_tracking_the_file, file_path)

        expect(query.exists?).to be false
      end
    end
  end

  describe '#expected_file_path_format_regexp' do
    let(:cleaner) { described_class.new }

    it 'validates correct artifact file paths' do
      valid_path =
        '4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce/2025_04_23/1/2/ci_build_artifacts.zip'
      expect(valid_path).to match(cleaner.send(:expected_file_path_format_regexp))
    end

    it 'rejects invalid file paths' do
      invalid_path = 'invalid/path/format.zip'
      expect(invalid_path).not_to match(cleaner.send(:expected_file_path_format_regexp))
    end
  end
end
