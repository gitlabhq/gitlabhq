# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::CodequalityReports do
  let(:codequality_report) { described_class.new }
  let(:degradation_1) do
    {
      "categories": [
        "Complexity"
      ],
      "check_name": "argument_count",
      "content": {
        "body": ""
      },
      "description": "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.",
      "fingerprint": "15cdb5c53afd42bc22f8ca366a08d547",
      "location": {
        "path": "foo.rb",
        "lines": {
          "begin": 10,
          "end": 10
        }
      },
      "other_locations": [],
      "remediation_points": 900000,
      "severity": "major",
      "type": "issue",
      "engine_name": "structure"
    }.with_indifferent_access
  end

  let(:degradation_2) do
    {
      "type": "Issue",
      "check_name": "Rubocop/Metrics/ParameterLists",
      "description": "Avoid parameter lists longer than 5 parameters. [12/5]",
      "categories": [
        "Complexity"
      ],
      "remediation_points": 550000,
      "location": {
        "path": "foo.rb",
        "positions": {
          "begin": {
            "column": 14,
            "line": 10
          },
          "end": {
            "column": 39,
            "line": 10
          }
        }
      },
      "content": {
        "body": "This cop checks for methods with too many parameters.\nThe maximum number of parameters is configurable.\nKeyword arguments can optionally be excluded from the total count."
      },
      "engine_name": "rubocop",
      "fingerprint": "ab5f8b935886b942d621399f5a2ca16e",
      "severity": "minor"
    }.with_indifferent_access
  end

  it { expect(codequality_report.degradations).to eq({}) }

  describe '#add_degradation' do
    context 'when there is a degradation' do
      before do
        codequality_report.add_degradation(degradation_1)
      end

      it 'adds degradation to codequality report' do
        expect(codequality_report.degradations.keys).to eq([degradation_1[:fingerprint]])
        expect(codequality_report.degradations.values.size).to eq(1)
      end
    end

    context 'when a required property is missing in the degradation' do
      let(:invalid_degradation) do
        {
          "type": "Issue",
          "check_name": "Rubocop/Metrics/ParameterLists",
          "description": "Avoid parameter lists longer than 5 parameters. [12/5]",
          "fingerprint": "ab5f8b935886b942d621399aefkaehfiaehf",
          "severity": "minor"
        }.with_indifferent_access
      end

      it 'sets location as an error' do
        codequality_report.add_degradation(invalid_degradation)

        expect(codequality_report.error_message).to eq("Invalid degradation format: The property '#/' did not contain a required property of 'location'")
      end
    end
  end

  describe '#set_error_message' do
    context 'when there is an error' do
      it 'sets errors' do
        codequality_report.set_error_message("error")

        expect(codequality_report.error_message).to eq("error")
      end
    end
  end

  describe '#degradations_count' do
    subject(:degradations_count) { codequality_report.degradations_count }

    context 'when there are many degradations' do
      before do
        codequality_report.add_degradation(degradation_1)
        codequality_report.add_degradation(degradation_2)
      end

      it 'returns the number of degradations' do
        expect(degradations_count).to eq(2)
      end
    end
  end

  describe '#all_degradations' do
    subject(:all_degradations) { codequality_report.all_degradations }

    context 'when there are many degradations' do
      before do
        codequality_report.add_degradation(degradation_1)
        codequality_report.add_degradation(degradation_2)
      end

      it 'returns all degradations' do
        expect(all_degradations).to contain_exactly(degradation_1, degradation_2)
      end
    end
  end
end
