# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodequalityReportsComparerEntity do
  let(:entity) { described_class.new(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::CodequalityReportsComparer.new(base_report, head_report) }
  let(:base_report) { Gitlab::Ci::Reports::CodequalityReports.new }
  let(:head_report) { Gitlab::Ci::Reports::CodequalityReports.new }
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

  describe '#as_json' do
    subject { entity.as_json }

    context 'when base and head report have errors' do
      before do
        base_report.add_degradation(degradation_1)
        head_report.add_degradation(degradation_2)
      end

      it 'contains correct compared codequality report details', :aggregate_failures do
        expect(subject[:status]).to eq(Gitlab::Ci::Reports::CodequalityReportsComparer::STATUS_FAILED)
        expect(subject[:resolved_errors].first).to include(:description, :severity, :file_path, :line)
        expect(subject[:new_errors].first).to include(:description, :severity, :file_path, :line)
        expect(subject[:existing_errors]).to be_empty
        expect(subject[:summary]).to include(total: 1, resolved: 1, errored: 1)
      end
    end
  end
end
