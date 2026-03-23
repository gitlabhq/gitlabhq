# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipelines::DestroyAssociationsService, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build_1) { create(:ci_build, pipeline: pipeline, project: project) }
  let_it_be(:build_2) { create(:ci_build, pipeline: pipeline, project: project) }

  let_it_be(:other_pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:other_build) { create(:ci_build, pipeline: other_pipeline, project: project) }
  let_it_be(:other_artifact) { create(:ci_job_artifact, :zip, job: other_build, project: project) }

  subject(:service) { described_class.new(pipeline) }

  describe '#destroy_records' do
    let!(:artifact_1) { create(:ci_job_artifact, :zip, job: build_1, project: project) }
    let!(:artifact_2) { create(:ci_job_artifact, :junit, job: build_1, project: project) }
    let!(:artifact_3) { create(:ci_job_artifact, :zip, job: build_2, project: project) }

    it 'destroys all artifacts belonging to the pipeline' do
      expect { service.destroy_records }.to change { Ci::JobArtifact.count }.by(-3)

      expect(Ci::JobArtifact.where(id: [artifact_1.id, artifact_2.id, artifact_3.id])).to be_empty
    end

    it 'does not destroy artifacts from other pipelines' do
      service.destroy_records

      expect(other_artifact.reload).to be_present
    end

    it 'batches builds using CTE' do
      expect(pipeline).to receive(:builds_with_cte).and_call_original

      service.destroy_records
    end

    context 'when pipeline has no builds' do
      let_it_be(:empty_pipeline) { create(:ci_pipeline, project: project) }

      it 'does not raise error' do
        expect { described_class.new(empty_pipeline).destroy_records }.not_to raise_error
      end
    end
  end

  describe '#update_statistics' do
    let!(:artifact_1) { create(:ci_job_artifact, :zip, job: build_1, project: project) }
    let!(:artifact_2) { create(:ci_job_artifact, :junit, job: build_1, project: project) }
    let!(:artifact_3) { create(:ci_job_artifact, :zip, job: build_2, project: project) }

    context 'with statistics accumulation across build batches' do
      before do
        stub_const("#{described_class}::BUILDS_BATCH_SIZE", 1)
      end

      it 'accumulates statistics from all build batches' do
        sizes = [artifact_1, artifact_2, artifact_3].to_h { |a| [a.id, a.size] }

        service.destroy_records

        project_increments = sizes.map do |id, size|
          have_attributes(amount: -size, ref: id)
        end

        expect(ProjectStatistics).to receive(:bulk_increment_statistic).once
          .with(project, :build_artifacts_size, match_array(project_increments))

        service.update_statistics
      end
    end
  end
end
