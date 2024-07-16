# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::PipelineArtifacts::CreateCodeQualityMrDiffReportService, feature_category: :pipeline_reports do
  describe '#execute' do
    let(:merge_request) { create(:merge_request) }
    let(:project) { merge_request.project }
    let(:head_pipeline) { create(:ci_pipeline, :success, :with_codequality_reports, project: project, merge_requests_as_head_pipeline: [merge_request]) }
    let(:base_pipeline) { create(:ci_pipeline, :success, project: project, ref: merge_request.target_branch, sha: merge_request.diff_base_sha) }

    subject { described_class.new(head_pipeline).execute }

    context 'when there are codequality reports' do
      context 'when pipeline passes' do
        context 'when degradations are present' do
          context 'when degradations already present in target branch pipeline' do
            before do
              create(:ci_build, :success, :codequality_reports, name: 'codequality', pipeline: base_pipeline, project: project)
            end

            it "does not persist a pipeline artifact" do
              expect { subject }.not_to change { Ci::PipelineArtifact.count }
            end
          end

          context 'when degradation is not present in target branch pipeline' do
            before do
              create(:ci_build, :success, :codequality_reports_without_degradation, name: 'codequality', pipeline: base_pipeline, project: project)
            end

            it 'persists a pipeline artifact' do
              expect { subject }.to change { Ci::PipelineArtifact.count }.by(1)
            end

            it 'persists the default file name' do
              subject

              pipeline_artifact = Ci::PipelineArtifact.first

              expect(pipeline_artifact.file.filename).to eq('code_quality_mr_diff.json')
            end

            it 'sets expire_at to 1 week' do
              freeze_time do
                subject

                pipeline_artifact = Ci::PipelineArtifact.first

                expect(pipeline_artifact.expire_at).to eq(1.week.from_now)
              end
            end

            it "artifact has pipeline's locked status" do
              subject

              artifact = Ci::PipelineArtifact.first

              expect(artifact.locked).to eq(head_pipeline.locked)
            end

            it 'does not persist the same artifact twice' do
              2.times { described_class.new(head_pipeline).execute }

              expect { subject }.not_to change { Ci::PipelineArtifact.count }
            end
          end
        end
      end
    end

    context 'when there are no codequality reports for head pipeline' do
      let(:head_pipeline) { create(:ci_pipeline, :success, project: project, merge_requests_as_head_pipeline: [merge_request]) }

      it "does not persist a pipeline artifact" do
        expect { subject }.not_to change { Ci::PipelineArtifact.count }
      end
    end

    context 'when there are no codequality reports for base pipeline' do
      let(:head_pipeline) { create(:ci_pipeline, :success, project: project, merge_requests_as_head_pipeline: [merge_request]) }

      it "does not persist a pipeline artifact" do
        expect { subject }.not_to change { Ci::PipelineArtifact.count }
      end
    end
  end
end
