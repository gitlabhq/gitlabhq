# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodequalityReportsComparerSerializer, feature_category: :code_quality do
  let(:project) { build_stubbed(:project) }
  let(:serializer) { described_class.new(project: project).represent(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::CodequalityReportsComparer.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:degradation_1) { build(:codequality_degradation_1) }
  let(:degradation_2) { build(:codequality_degradation_2) }

  describe '#to_json' do
    subject { serializer.as_json }

    context 'when base report has error and head has a different error' do
      before do
        base_report.add_degradation(degradation_1)
        head_report.add_degradation(degradation_2)
      end

      it 'matches the schema' do
        expect(subject).to match_schema('entities/codequality_reports_comparer')
      end
    end

    context 'when base report has no error and head has errors' do
      before do
        head_report.add_degradation(degradation_1)
      end

      it 'matches the schema' do
        expect(subject).to match_schema('entities/codequality_reports_comparer')
      end
    end
  end
end
