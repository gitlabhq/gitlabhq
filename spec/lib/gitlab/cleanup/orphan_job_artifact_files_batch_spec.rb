# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFilesBatch do
  let(:batch_size) { 10 }
  let(:dry_run) { true }

  subject(:batch) { described_class.new(batch_size: batch_size, dry_run: dry_run) }

  context 'no dry run' do
    let(:dry_run) { false }

    it 'deletes only orphan job artifacts from disk' do
      job_artifact = create(:ci_job_artifact, :archive)
      orphan_artifact = create(:ci_job_artifact, :archive)
      batch << artifact_path(job_artifact)
      batch << artifact_path(orphan_artifact)
      orphan_artifact.delete

      batch.clean!

      expect(batch.artifact_files.count).to eq(2)
      expect(batch.lost_and_found.count).to eq(1)
      expect(batch.lost_and_found.first.artifact_id).to eq(orphan_artifact.id)
      expect(File.exist?(job_artifact.file.path)).to be_truthy
      expect(File.exist?(orphan_artifact.file.path)).to be_falsey
    end
  end

  context 'with dry run' do
    it 'does not remove files' do
      job_artifact = create(:ci_job_artifact, :archive)
      batch << job_artifact.file.path
      job_artifact.delete

      expect(batch).not_to receive(:remove_file!)

      batch.clean!

      expect(File.exist?(job_artifact.file.path)).to be_truthy
    end
  end

  def artifact_path(job_artifact)
    Pathname.new(job_artifact.file.path).parent.to_s
  end
end
