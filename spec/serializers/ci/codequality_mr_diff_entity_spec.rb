# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CodequalityMrDiffEntity do
  let(:entity) { described_class.new(mr_diff_report) }
  let(:mr_diff_report) { Gitlab::Ci::Reports::CodequalityMrDiff.new(codequality_report) }
  let(:codequality_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:degradation_1) { build(:codequality_degradation_1) }
  let(:degradation_2) { build(:codequality_degradation_2) }

  describe '#as_json' do
    subject(:report) { entity.as_json }

    context 'when quality report has degradations' do
      before do
        codequality_report.add_degradation(degradation_1)
        codequality_report.add_degradation(degradation_2)
      end

      it 'contains correct codequality mr diff report', :aggregate_failures do
        expect(report[:files].keys).to eq(["file_a.rb"])
        expect(report[:files]["file_a.rb"].first).to include(:line, :description, :severity)
      end
    end
  end
end
