# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Codequality::CodeClimate do
  describe '#parse!' do
    subject(:parse) { described_class.new.parse!(code_climate, codequality_report) }

    let(:codequality_report) { Gitlab::Ci::Reports::CodequalityReports.new }
    let(:code_climate) do
      [
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
        }
      ].to_json
    end

    context "when data is code_climate style JSON" do
      context "when there are no degradations" do
        let(:code_climate) { [].to_json }

        it "returns a codequality report" do
          expect { parse }.not_to raise_error

          expect(codequality_report.degradations_count).to eq(0)
        end
      end

      context "when there are degradations" do
        it "returns a codequality report" do
          expect { parse }.not_to raise_error

          expect(codequality_report.degradations_count).to eq(1)
        end
      end
    end

    context "when data is not a valid JSON string" do
      let(:code_climate) do
        [
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
          }
        ]
      end

      it "sets error_message" do
        expect { parse }.not_to raise_error

        expect(codequality_report.error_message).to include('JSON parsing failed')
      end
    end

    context 'when degradations contain an invalid one' do
      let(:code_climate) do
        [
          {
          "type": "Issue",
          "check_name": "Rubocop/Metrics/ParameterLists",
          "description": "Avoid parameter lists longer than 5 parameters. [12/5]",
          "fingerprint": "ab5f8b935886b942d621399aefkaehfiaehf",
          "severity": "minor"
          },
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
          }
        ].to_json
      end

      it 'stops parsing the report' do
        expect { parse }.not_to raise_error

        expect(codequality_report.degradations_count).to eq(0)
      end
    end
  end
end
