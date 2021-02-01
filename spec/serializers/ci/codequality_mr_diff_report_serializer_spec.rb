# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CodequalityMrDiffReportSerializer do
  let(:serializer) { described_class.new.represent(mr_diff_report) }
  let(:mr_diff_report) { Gitlab::Ci::Reports::CodequalityMrDiff.new(codequality_report) }
  let(:codequality_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:degradation_1) { build(:codequality_degradation_1) }
  let(:degradation_2) { build(:codequality_degradation_2) }

  describe '#to_json' do
    subject { serializer.as_json }

    context 'when quality report has degradations' do
      before do
        codequality_report.add_degradation(degradation_1)
        codequality_report.add_degradation(degradation_2)
      end

      it 'matches the schema' do
        expect(subject).to match_schema('entities/codequality_mr_diff_report')
      end
    end

    context 'when quality report has no degradations' do
      it 'matches the schema' do
        expect(subject).to match_schema('entities/codequality_mr_diff_report')
      end
    end
  end
end
