# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::GenerateCoverageReportsService, feature_category: :code_testing do
  let_it_be(:project) { create(:project, :repository) }

  let(:service) { described_class.new(project) }

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

      context 'when there is a parsing error' do
        before do
          allow_next_found_instance_of(MergeRequest) do |merge_request|
            allow(merge_request).to receive(:new_paths).and_raise(StandardError)
          end
        end

        it 'returns status with error message and tracks the error' do
          expect(service).to receive(:track_exception).and_call_original

          expect(subject[:status]).to eq(:error)
          expect(subject[:status_reason]).to include('An error occurred while fetching coverage reports.')
        end
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
        expect(service).not_to receive(:track_exception)

        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('An error occurred while fetching coverage reports.')
      end
    end

    context 'when head pipeline has coverage reports and no merge request associated' do
      let!(:head_pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }
      let!(:base_pipeline) { nil }

      it 'returns status and error message' do
        expect(service).not_to receive(:track_exception)

        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('An error occurred while fetching coverage reports.')
      end
    end
  end

  describe '#latest?' do
    subject { service.latest?(base_pipeline, head_pipeline, data) }

    let!(:base_pipeline) { nil }
    let!(:head_pipeline) { create(:ci_pipeline, :with_coverage_reports, project: project) }
    let!(:child_pipeline) { create(:ci_pipeline, child_of: head_pipeline) }
    let!(:key) { service.send(:key, base_pipeline, head_pipeline) }

    let(:data) { { key: key } }

    context 'when cache key is latest' do
      it { is_expected.to be_truthy }
    end

    context 'when head pipeline has been updated' do
      before do
        head_pipeline.update_column(:updated_at, 1.minute.from_now)
      end

      it { is_expected.to be_falsy }
    end

    context 'when cache key is empty' do
      let(:data) { { key: nil } }

      it { is_expected.to be_falsy }
    end

    context 'when the pipeline has a child that is updated' do
      before do
        child_pipeline.update_column(:updated_at, 1.minute.from_now)
      end

      it { is_expected.to be_falsy }
    end
  end
end
