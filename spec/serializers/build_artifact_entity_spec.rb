# frozen_string_literal: true

require 'spec_helper'

describe BuildArtifactEntity do
  let(:job) { create(:ci_build) }
  let(:artifact) { create(:ci_job_artifact, :codequality, expire_at: 1.hour.from_now, job: job) }

  let(:entity) do
    described_class.new(artifact, request: double)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains job name' do
      expect(subject[:name]).to eq "test:codequality"
    end

    it 'exposes information about expiration of artifacts' do
      expect(subject).to include(:expired, :expire_at)
    end

    it 'contains paths to the artifacts' do
      expect(subject[:path])
        .to include "jobs/#{job.id}/artifacts/download?file_type=codequality"

      expect(subject[:keep_path])
        .to include "jobs/#{job.id}/artifacts/keep"

      expect(subject[:browse_path])
        .to include "jobs/#{job.id}/artifacts/browse"
    end
  end
end
