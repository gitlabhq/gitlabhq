# frozen_string_literal: true

require 'spec_helper'

describe Ci::CompareAccessibilityReportsService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has accessibility reports' do
      let(:base_pipeline) { nil }
      let(:head_pipeline) { create(:ci_pipeline, :with_accessibility_reports, project: project) }

      it 'returns status and data' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]).to match_schema('entities/accessibility_reports_comparer')
      end
    end

    context 'when base and head pipelines have accessibility reports' do
      let(:base_pipeline) { create(:ci_pipeline, :with_accessibility_reports, project: project) }
      let(:head_pipeline) { create(:ci_pipeline, :with_accessibility_reports, project: project) }

      it 'returns status and data' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]).to match_schema('entities/accessibility_reports_comparer')
      end
    end
  end

  describe '#latest?' do
    subject { service.latest?(base_pipeline, head_pipeline, data) }

    let!(:base_pipeline) { nil }
    let!(:head_pipeline) { create(:ci_pipeline, :with_accessibility_reports, project: project) }
    let!(:key) { service.send(:key, base_pipeline, head_pipeline) }

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
end
