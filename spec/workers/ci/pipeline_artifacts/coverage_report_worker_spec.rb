# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifacts::CoverageReportWorker, feature_category: :code_testing do
  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  describe '#perform' do
    let(:pipeline_id) { pipeline.id }

    subject { described_class.new.perform(pipeline_id) }

    context 'when pipeline exists' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      it 'calls the pipeline coverage report service' do
        expect_next_instance_of(::Ci::PipelineArtifacts::CoverageReportService, pipeline) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end

    context 'when the pipeline is part of a hierarchy' do
      let_it_be(:root_ancestor_pipeline) { create(:ci_pipeline, :success) }
      let_it_be(:pipeline) { create(:ci_pipeline, :success, child_of: root_ancestor_pipeline) }
      let_it_be(:another_child_pipeline) { create(:ci_pipeline, :success, child_of: root_ancestor_pipeline) }

      context 'when all pipelines is complete' do
        it 'calls the pipeline coverage report service on the root ancestor pipeline' do
          expect_next_instance_of(::Ci::PipelineArtifacts::CoverageReportService, root_ancestor_pipeline) do |service|
            expect(service).to receive(:execute)
          end

          subject
        end
      end

      context 'when the pipeline hierarchy has incomplete pipeline' do
        before do
          another_child_pipeline.update!(status: :running)
        end

        it 'does not call pipeline coverage report service' do
          expect(Ci::PipelineArtifacts::CoverageReportService).not_to receive(:new)

          subject
        end
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }

      it 'does not call pipeline create artifact service' do
        expect(Ci::PipelineArtifacts::CoverageReportService).not_to receive(:new)

        subject
      end
    end
  end
end
