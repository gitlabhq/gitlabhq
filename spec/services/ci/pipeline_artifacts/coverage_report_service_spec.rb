# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::PipelineArtifacts::CoverageReportService do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }

    subject { described_class.new(pipeline).execute }

    shared_examples 'creating a pipeline coverage report' do
      context 'when pipeline is finished' do
        it 'creates a pipeline artifact' do
          expect { subject }.to change { Ci::PipelineArtifact.count }.from(0).to(1)
        end

        it 'persists the default file name' do
          subject

          file = Ci::PipelineArtifact.first.file

          expect(file.filename).to eq('code_coverage.json')
        end

        it 'sets expire_at to 1 week' do
          freeze_time do
            subject

            pipeline_artifact = Ci::PipelineArtifact.first

            expect(pipeline_artifact.expire_at).to eq(1.week.from_now)
          end
        end
      end

      context 'when pipeline artifact has already been created' do
        it 'does not raise an error and does not persist the same artifact twice' do
          expect { 2.times { described_class.new(pipeline).execute } }.not_to raise_error

          expect(Ci::PipelineArtifact.count).to eq(1)
        end
      end
    end

    context 'when pipeline has coverage report' do
      let!(:pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }

      it_behaves_like 'creating a pipeline coverage report'
    end

    context 'when pipeline has coverage report from child pipeline' do
      let!(:pipeline) { create(:ci_pipeline, :success, project: project) }
      let!(:child_pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project, child_of: pipeline) }

      it_behaves_like 'creating a pipeline coverage report'
    end

    context 'when pipeline is running and coverage report does not exist' do
      let(:pipeline) { create(:ci_pipeline, :running) }

      it 'does not persist data' do
        expect { subject }.not_to change { Ci::PipelineArtifact.count }
      end
    end
  end
end
