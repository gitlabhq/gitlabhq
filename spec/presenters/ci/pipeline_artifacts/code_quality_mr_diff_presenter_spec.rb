# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifacts::CodeQualityMrDiffPresenter do
  let(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_codequality_mr_diff_report) }
  let(:merge_request) { double(id: 123456789, new_paths: filenames) }

  subject(:presenter) { described_class.new(pipeline_artifact) }

  describe '#for_files' do
    subject(:quality_data) { presenter.for_files(merge_request) }

    context 'when code quality has data' do
      context 'when filenames is empty' do
        let(:filenames) { %w() }

        it 'returns hash without quality' do
          expect(quality_data).to match(files: {})
        end
      end

      context 'when filenames do not match code quality data' do
        let(:filenames) { %w(demo.rb) }

        it 'returns hash without quality' do
          expect(quality_data).to match(files: {})
        end
      end

      context 'when filenames matches code quality data' do
        context 'when asking for one filename' do
          let(:filenames) { %w(file_a.rb) }

          it 'returns quality for the given filename' do
            expect(quality_data).to match(
              files: {
                "file_a.rb" => [
                  { line: 10, description: "Avoid parameter lists longer than 5 parameters. [12/5]", severity: "major" },
                  { line: 10, description: "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.", severity: "minor" }
                ]
              }
            )
          end
        end

        context 'when asking for multiple filenames' do
          let(:filenames) { %w(file_a.rb file_b.rb) }

          it 'returns quality for the given filenames' do
            expect(quality_data).to match(
              files: {
                "file_a.rb" => [
                  { line: 10, description: "Avoid parameter lists longer than 5 parameters. [12/5]", severity: "major" },
                  { line: 10, description: "Method `new_array` has 12 arguments (exceeds 4 allowed). Consider refactoring.", severity: "minor" }
                ],
                "file_b.rb" => [
                  { line: 10, description: "This cop checks for methods with too many parameters.\nThe maximum number of parameters is configurable.\nKeyword arguments can optionally be excluded from the total count.", severity: "minor" }
                ]
              }
            )
          end
        end
      end
    end
  end
end
