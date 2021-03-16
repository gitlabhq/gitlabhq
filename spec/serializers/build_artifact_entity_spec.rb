# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildArtifactEntity do
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

    it 'exposes the artifact download path' do
      expect(subject[:path]).to include "jobs/#{job.id}/artifacts/download?file_type=codequality"
    end

    context 'with remove_duplicate_artifact_exposure_paths enabled' do
      before do
        stub_feature_flags(remove_duplicate_artifact_exposure_paths: true)
      end

      it 'has no keep or browse path' do
        expect(subject).not_to include(:keep_path)
        expect(subject).not_to include(:browse_path)
      end
    end

    context 'with remove_duplicate_artifact_exposure_paths disabled' do
      before do
        stub_feature_flags(remove_duplicate_artifact_exposure_paths: false)
      end

      it 'has keep and browse paths' do
        expect(subject[:keep_path]).to be_present
        expect(subject[:browse_path]).to be_present
      end
    end
  end
end
