# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GenerateCoverageReportsService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has coverage reports' do
      let!(:merge_request) { create(:merge_request, :with_coverage_reports, source_project: project) }
      let!(:service) { described_class.new(project, nil, id: merge_request.id) }
      let!(:head_pipeline) { merge_request.head_pipeline }
      let!(:base_pipeline) { nil }

      it 'returns status and data', :aggregate_failures do
        expect_any_instance_of(Ci::PipelineArtifact) do |instance|
          expect(instance).to receive(:present)
          expect(instance).to receive(:for_files).with(merge_request.new_paths).and_call_original
        end

        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]).to eq(files: {})
      end
    end

    context 'when head pipeline does not have a coverage report artifact' do
      let!(:merge_request) { create(:merge_request, :with_coverage_reports, source_project: project) }
      let!(:service) { described_class.new(project, nil, id: merge_request.id) }
      let!(:head_pipeline) { merge_request.head_pipeline }
      let!(:base_pipeline) { nil }

      before do
        head_pipeline.pipeline_artifacts.destroy_all # rubocop: disable Cop/DestroyAll
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('An error occurred while fetching coverage reports.')
      end
    end

    context 'when head pipeline has coverage reports and no merge request associated' do
      let!(:head_pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }
      let!(:base_pipeline) { nil }

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('An error occurred while fetching coverage reports.')
      end
    end
  end
end
