# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DestroyAssociationsService do
  let_it_be(:artifact_1, refind: true) { create(:ci_job_artifact, :zip) }
  let_it_be(:artifact_2, refind: true) { create(:ci_job_artifact, :zip) }
  let_it_be(:artifact_3, refind: true) { create(:ci_job_artifact, :zip, project: artifact_1.project) }

  let(:artifacts) { Ci::JobArtifact.where(id: [artifact_1.id, artifact_2.id, artifact_3.id]) }
  let(:service) { described_class.new(artifacts) }

  describe '#destroy_records' do
    it 'removes artifacts without updating statistics' do
      expect_next_instance_of(Ci::JobArtifacts::DestroyBatchService) do |service|
        expect(service).to receive(:execute).with(update_stats: false).and_call_original
      end

      expect { service.destroy_records }.to change { Ci::JobArtifact.count }.by(-3)
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
      stub_const("#{described_class}::BATCH_SIZE", 2)
      service.destroy_records
    end

    it 'updates project statistics' do
      expect(ProjectStatistics).to receive(:bulk_increment_statistic).once
        .with(artifact_1.project, :build_artifacts_size, match_array([-artifact_1.size, -artifact_3.size]))
      expect(ProjectStatistics).to receive(:bulk_increment_statistic).once
        .with(artifact_2.project, :build_artifacts_size, match_array([-artifact_2.size]))

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
