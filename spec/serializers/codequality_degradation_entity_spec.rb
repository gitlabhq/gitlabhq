# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodequalityDegradationEntity do
  let(:entity) { described_class.new(codequality_degradation) }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when codequality contains an error' do
      context 'when line is included in location' do
        let(:codequality_degradation) do
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

        it 'contains correct codequality degradation details', :aggregate_failures do
          expect(subject[:description]).to eq("Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.")
          expect(subject[:severity]).to eq("major")
          expect(subject[:file_path]).to eq("foo.rb")
          expect(subject[:line]).to eq(10)
        end
      end

      context 'when line is included in positions' do
        let(:codequality_degradation) do
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
                  "column": 24,
                  "line": 14
                },
                "end": {
                  "column": 49,
                  "line": 14
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

        it 'contains correct codequality degradation details', :aggregate_failures do
          expect(subject[:description]).to eq("Avoid parameter lists longer than 5 parameters. [12/5]")
          expect(subject[:severity]).to eq("minor")
          expect(subject[:file_path]).to eq("foo.rb")
          expect(subject[:line]).to eq(14)
        end
      end
    end
  end
end
