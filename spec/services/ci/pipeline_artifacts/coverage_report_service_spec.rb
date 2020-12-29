# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::PipelineArtifacts::CoverageReportService do
  describe '#execute' do
    subject { described_class.new.execute(pipeline) }

    context 'when pipeline has coverage reports' do
      let(:project) { create(:project, :repository) }
      let(:pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }

      context 'when pipeline is finished' do
        it 'creates a pipeline artifact' do
          subject

          expect(Ci::PipelineArtifact.count).to eq(1)
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
        it 'do not raise an error and do not persist the same artifact twice' do
          expect { 2.times { described_class.new.execute(pipeline) } }.not_to raise_error(ActiveRecord::RecordNotUnique)

          expect(Ci::PipelineArtifact.count).to eq(1)
        end
      end
    end

    context 'when pipeline is running and coverage report does not exist' do
      let(:pipeline) { create(:ci_pipeline, :running) }

      it 'does not persist data' do
        subject

        expect(Ci::PipelineArtifact.count).to eq(0)
      end
    end
  end
end
