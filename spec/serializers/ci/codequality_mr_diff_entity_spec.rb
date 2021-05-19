# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CodequalityMrDiffEntity do
  let(:entity) { described_class.new(mr_diff_report) }
  let(:mr_diff_report) { Gitlab::Ci::Reports::CodequalityMrDiff.new(codequality_report.all_degradations) }
  let(:codequality_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:major) { build(:codequality_degradation, :major) }
  let(:minor) { build(:codequality_degradation, :minor) }

  describe '#as_json' do
    subject(:report) { entity.as_json }

    context 'when quality report has degradations' do
      before do
        codequality_report.add_degradation(major)
        codequality_report.add_degradation(minor)
      end

      it 'contains correct codequality mr diff report', :aggregate_failures do
        expect(report[:files].keys).to eq(["file_a.rb"])
        expect(report[:files]["file_a.rb"].first).to include(:line, :description, :severity)
      end
    end
  end
end
