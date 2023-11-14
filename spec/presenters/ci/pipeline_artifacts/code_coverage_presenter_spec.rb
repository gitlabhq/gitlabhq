# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifacts::CodeCoveragePresenter do
  let(:pipeline_artifact) { create(:ci_pipeline_artifact, :with_code_coverage_with_multiple_files) }

  subject(:presenter) { described_class.new(pipeline_artifact) }

  describe '#for_files' do
    subject { presenter.for_files(filenames) }

    context 'when code coverage has data' do
      context 'when filenames is empty' do
        let(:filenames) { %w[] }

        it 'returns hash without coverage' do
          expect(subject).to match(files: {})
        end
      end

      context 'when filenames do not match code coverage data' do
        let(:filenames) { %w[demo.rb] }

        it 'returns hash without coverage' do
          expect(subject).to match(files: {})
        end
      end

      context 'when filenames matches code coverage data' do
        context 'when asking for one filename' do
          let(:filenames) { %w[file_a.rb] }

          it 'returns coverage for the given filename' do
            expect(subject).to match(files: { "file_a.rb" => { "1" => 1, "2" => 1, "3" => 1 } })
          end
        end

        context 'when asking for multiple filenames' do
          let(:filenames) { %w[file_a.rb file_b.rb] }

          it 'returns coverage for a the given filenames' do
            expect(subject).to match(
              files: {
                "file_a.rb" => {
                  "1" => 1,
                  "2" => 1,
                  "3" => 1
                },
                "file_b.rb" => {
                  "1" => 0,
                  "2" => 0,
                  "3" => 0
                }
              }
            )
          end
        end
      end
    end
  end
end
