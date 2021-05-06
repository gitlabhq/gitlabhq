# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CodequalityMrDiffReportSerializer do
  let(:serializer) { described_class.new.represent(mr_diff_report) }
  let(:mr_diff_report) { Gitlab::Ci::Reports::CodequalityMrDiff.new(codequality_report.all_degradations) }
  let(:codequality_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:major) { build(:codequality_degradation, :major) }
  let(:minor) { build(:codequality_degradation, :minor) }

  describe '#to_json' do
    subject { serializer.as_json }

    context 'when quality report has degradations' do
      before do
        codequality_report.add_degradation(major)
        codequality_report.add_degradation(minor)
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
