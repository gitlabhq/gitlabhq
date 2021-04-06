# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildArtifactEntity do
  let_it_be(:job) { create(:ci_build) }
  let_it_be(:artifact) { create(:ci_job_artifact, :codequality, expire_at: 1.hour.from_now, job: job) }

  let(:options) { { request: double } }

  let(:entity) do
    described_class.represent(artifact, options)
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

    context 'when project is specified in options' do
      let(:options) { super().merge(project: job.project) }

      it 'doesnt get a project from the artifact' do
        expect(artifact).not_to receive(:project)

        subject
      end
    end
  end
end
