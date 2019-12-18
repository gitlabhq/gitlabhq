# frozen_string_literal: true

require 'spec_helper'

describe BuildArtifactEntity do
  let(:job) { create(:ci_build, name: 'test:job', artifacts_expire_at: 1.hour.from_now) }
  let!(:archive) { create(:ci_job_artifact, :archive, job: job) }
  let!(:metadata) { create(:ci_job_artifact, :metadata, job: job) }

  let(:entity) do
    described_class.new(job, request: double)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains job name' do
      expect(subject[:name]).to eq 'test:job'
    end

    it 'exposes information about expiration of artifacts' do
      expect(subject).to include(:expired, :expire_at)
    end

    it 'contains paths to the artifacts' do
      expect(subject[:path])
        .to include "jobs/#{job.id}/artifacts/download"

      expect(subject[:keep_path])
        .to include "jobs/#{job.id}/artifacts/keep"

      expect(subject[:browse_path])
        .to include "jobs/#{job.id}/artifacts/browse"
    end
  end
end
