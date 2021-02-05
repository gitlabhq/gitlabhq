# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::CodequalityMrDiff do
  let(:codequality_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:degradation_1) { build(:codequality_degradation_1) }
  let(:degradation_2) { build(:codequality_degradation_2) }
  let(:degradation_3) { build(:codequality_degradation_3) }

  describe '#initialize!' do
    subject(:report) { described_class.new(codequality_report) }

    context 'when quality has degradations' do
      context 'with several degradations on the same line' do
        before do
          codequality_report.add_degradation(degradation_1)
          codequality_report.add_degradation(degradation_2)
        end

        it 'generates quality report for mr diff' do
          expect(report.files).to match(
            "file_a.rb" => [
              { line: 10, description: "Avoid parameter lists longer than 5 parameters. [12/5]", severity: "major" },
              { line: 10, description: "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.", severity: "major" }
            ]
          )
        end
      end

      context 'with several degradations on several files' do
        before do
          codequality_report.add_degradation(degradation_1)
          codequality_report.add_degradation(degradation_2)
          codequality_report.add_degradation(degradation_3)
        end

        it 'returns quality report for mr diff' do
          expect(report.files).to match(
            "file_a.rb" => [
              { line: 10, description: "Avoid parameter lists longer than 5 parameters. [12/5]", severity: "major" },
              { line: 10, description: "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.", severity: "major" }
            ],
            "file_b.rb" => [
              { line: 10, description: "Avoid parameter lists longer than 5 parameters. [12/5]", severity: "minor" }
            ]
          )
        end
      end
    end

    context 'when quality has no degradation' do
      it 'returns an empty hash' do
        expect(report.files).to match({})
      end
    end
  end
end
