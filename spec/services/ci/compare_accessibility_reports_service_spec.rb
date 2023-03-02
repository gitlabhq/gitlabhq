# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareAccessibilityReportsService, feature_category: :continuous_integration do
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
end
