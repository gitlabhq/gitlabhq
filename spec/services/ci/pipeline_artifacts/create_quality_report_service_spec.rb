# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::PipelineArtifacts::CreateQualityReportService do
  describe '#execute' do
    subject(:pipeline_artifact) { described_class.new.execute(pipeline) }

    context 'when pipeline has codequality reports' do
      let(:project) { create(:project, :repository) }

      describe 'pipeline completed status' do
        using RSpec::Parameterized::TableSyntax

        where(:status, :result) do
          :success   | 1
          :failed    | 1
          :canceled  | 1
          :skipped   | 1
        end

        with_them do
          let(:pipeline) { create(:ci_pipeline, :with_codequality_reports, status: status, project: project) }

          it 'creates a pipeline artifact' do
            expect { pipeline_artifact }.to change(Ci::PipelineArtifact, :count).by(result)
          end

          it 'persists the default file name' do
            expect(pipeline_artifact.file.filename).to eq('code_quality.json')
          end

          it 'sets expire_at to 1 week' do
            freeze_time do
              expect(pipeline_artifact.expire_at).to eq(1.week.from_now)
            end
          end
        end
      end

      context 'when pipeline artifact has already been created' do
        let(:pipeline) { create(:ci_pipeline, :with_codequality_reports, project: project) }

        it 'does not persist the same artifact twice' do
          2.times { described_class.new.execute(pipeline) }

          expect(Ci::PipelineArtifact.count).to eq(1)
        end
      end
    end

    context 'when pipeline is not completed and codequality report does not exist' do
      let(:pipeline) { create(:ci_pipeline, :running) }

      it 'does not persist data' do
        pipeline_artifact

        expect(Ci::PipelineArtifact.count).to eq(0)
      end
    end
  end
end
