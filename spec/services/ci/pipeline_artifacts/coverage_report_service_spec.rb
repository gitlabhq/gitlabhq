# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifacts::CoverageReportService, feature_category: :pipeline_reports do
  let!(:merge_request) { create(:merge_request, head_pipeline: pipeline, source_project: project) }

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }

    subject { described_class.new(pipeline).execute }

    shared_examples 'creating or updating a pipeline coverage report' do
      context 'when pipeline is finished' do
        it 'creates or updates a pipeline artifact' do
          subject

          expect(pipeline.reload.pipeline_artifacts.count).to eq(1)
        end

        it 'persists the default file name' do
          subject

          file = Ci::PipelineArtifact.first.file

          expect(file.filename).to eq('code_coverage.json')
        end

        it 'sets expire_at to 1 week from now' do
          freeze_time do
            subject

            pipeline_artifact = Ci::PipelineArtifact.first

            expect(pipeline_artifact.expire_at).to eq(1.week.from_now)
          end
        end

        it 'logs relevant information' do
          allow(Gitlab::AppLogger).to receive(:info).and_call_original
          expect(Gitlab::AppLogger).to receive(:info).with({
                                                             project_id: project.id,
                                                             pipeline_id: pipeline.id,
                                                             pipeline_artifact_id: kind_of(Numeric),
                                                             message: kind_of(String)
                                                           })

          subject
        end
      end
    end

    context 'when pipeline has coverage report' do
      let(:pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }

      it_behaves_like 'creating or updating a pipeline coverage report'

      it "artifact has pipeline's locked status" do
        subject

        artifact = Ci::PipelineArtifact.first

        expect(artifact.locked).to eq(pipeline.locked)
      end
    end

    context 'when pipeline has coverage report from child pipeline' do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let!(:child_pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project, child_of: pipeline) }

      it_behaves_like 'creating or updating a pipeline coverage report'
    end

    context 'when pipeline has existing pipeline artifact for coverage report' do
      let!(:pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }
      let!(:child_pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project, child_of: pipeline) }

      let!(:pipeline_artifact) do
        create(:ci_pipeline_artifact, :with_coverage_report, pipeline: pipeline, expire_at: 1.day.from_now)
      end

      it_behaves_like 'creating or updating a pipeline coverage report'
    end

    context 'when pipeline is running and coverage report does not exist' do
      let(:pipeline) { create(:ci_pipeline, :running) }

      it 'does not persist data' do
        expect { subject }.not_to change { Ci::PipelineArtifact.count }.from(0)
      end
    end
  end
end
