# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Observability::ExportWorker, feature_category: :observability do
  describe '#perform' do
    subject(:perform_export) { described_class.new.perform(pipeline_id) }

    let_it_be(:project) { create(:project) }

    context 'when pipeline exists with unblocked user' do
      let(:pipeline) { create(:ci_pipeline, project: project, user: create(:user)) }
      let(:pipeline_id) { pipeline.id }

      it 'calls ExportService with the pipeline' do
        expect_next_instance_of(Ci::Observability::ExportService, pipeline) do |service|
          expect(service).to receive(:execute)
        end

        perform_export
      end
    end

    context 'when pipeline exists with blocked user' do
      let(:pipeline) { create(:ci_pipeline, project: project, user: create(:user, :blocked)) }
      let(:pipeline_id) { pipeline.id }

      it 'does not call ExportService' do
        expect(Ci::Observability::ExportService).not_to receive(:new)

        perform_export
      end
    end

    context 'when pipeline exists without user' do
      let(:pipeline) { create(:ci_pipeline, project: project, user: nil) }
      let(:pipeline_id) { pipeline.id }

      it 'calls ExportService' do
        expect_next_instance_of(Ci::Observability::ExportService, pipeline) do |service|
          expect(service).to receive(:execute)
        end

        perform_export
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not raise exception and does not call ExportService', :aggregate_failures do
        expect { perform_export }.not_to raise_error
        expect(Ci::Observability::ExportService).not_to receive(:new)
      end
    end
  end
end
