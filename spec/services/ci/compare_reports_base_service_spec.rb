# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareReportsBaseService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project) }
  let_it_be_with_reload(:project) { create(:project) }

  let!(:base_pipeline) { nil }
  let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }
  let!(:key) { service.send(:key, base_pipeline, head_pipeline) }

  describe '#latest?' do
    subject { service.latest?(base_pipeline, head_pipeline, data) }

    context 'when cache key is latest' do
      let(:data) { { key: key } }

      it { is_expected.to be_truthy }
    end

    context 'when cache key is outdated' do
      before do
        head_pipeline.update_column(:updated_at, 10.minutes.ago)
      end

      let(:data) { { key: key } }

      it { is_expected.to be_falsy }
    end

    context 'when cache key is empty' do
      let(:data) { { key: nil } }

      it { is_expected.to be_falsy }
    end
  end

  describe '#execute' do
    context 'when base_pipeline is running' do
      let!(:base_pipeline) { create(:ci_pipeline, :running, project: project) }

      subject { service.execute(base_pipeline, head_pipeline) }

      it { is_expected.to eq(status: :parsing, key: key) }
    end

    context 'when the head report is missing' do
      subject(:result) { service.execute(base_pipeline, nil) }

      let!(:key) { service.send(:key, base_pipeline, nil) }

      before do
        # The base class does not implement get_report. Subclasses that cannot
        # build a report without a pipeline (test, accessibility, codequality,
        # metrics) return nil for a nil pipeline.
        allow(service).to receive(:get_report).and_return(nil)
      end

      # :error rather than :parsing, because the pipeline may never arrive and
      # :parsing would poll unboundedly. The key is included so the cache
      # self-heals once a pipeline finally appears.
      it 'returns an error payload with the cache key instead of raising', :aggregate_failures do
        expect { result }.not_to raise_error
        expect(result[:status]).to eq(:error)
        expect(result[:key]).to eq(key)
        expect(result[:status_reason]).to eq(_('This merge request does not have reports to compare.'))
      end
    end
  end
end
