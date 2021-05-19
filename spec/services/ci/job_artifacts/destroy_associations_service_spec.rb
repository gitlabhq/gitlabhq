# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyAssociationsService do
  let(:artifacts) { Ci::JobArtifact.all }
  let(:service) { described_class.new(artifacts) }

  let_it_be(:artifact, refind: true) do
    create(:ci_job_artifact)
  end

  before do
    artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
    artifact.save!
  end

  describe '#destroy_records' do
    it 'removes artifacts without updating statistics' do
      expect(ProjectStatistics).not_to receive(:increment_statistic)

      expect { service.destroy_records }.to change { Ci::JobArtifact.count }
    end

    context 'when there are no artifacts' do
      let(:artifacts) { Ci::JobArtifact.none }

      it 'does not raise error' do
        expect { service.destroy_records }.not_to raise_error
      end
    end
  end

  describe '#update_statistics' do
    before do
      service.destroy_records
    end

    it 'updates project statistics' do
      expect(ProjectStatistics).to receive(:increment_statistic).once
            .with(artifact.project, :build_artifacts_size, -artifact.file.size)

      service.update_statistics
    end

    context 'when there are no artifacts' do
      let(:artifacts) { Ci::JobArtifact.none }

      it 'does not raise error' do
        expect { service.update_statistics }.not_to raise_error
      end
    end
  end
end
