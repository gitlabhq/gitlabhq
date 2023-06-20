# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/failed_tests'

RSpec.describe FailedTests do
  let(:report_file) { 'spec/fixtures/scripts/test_report.json' }
  let(:options) { described_class::DEFAULT_OPTIONS.merge(previous_tests_report_path: report_file) }
  let(:failure_path) { 'path/to/fail_file_spec.rb' }
  let(:other_failure_path) { 'path/to/fail_file_spec_2.rb' }
  let(:file_contents_as_json) do
    {
      'suites' => [
        {
          'failed_count' => 1,
          'name' => 'rspec unit pg14 10/12',
          'test_cases' => [
            {
              'status' => 'failed',
              'file' => failure_path
            }
          ]
        },
        {
          'failed_count' => 1,
          'name' => 'rspec-ee unit pg14',
          'test_cases' => [
            {
              'status' => 'failed',
              'file' => failure_path
            }
          ]
        },
        {
          'failed_count' => 1,
          'name' => 'rspec unit pg15 10/12',
          'test_cases' => [
            {
              'status' => 'failed',
              'file' => other_failure_path
            }
          ]
        }
      ]
    }
  end

  subject { described_class.new(options) }

  describe '#output_failed_tests' do
    context 'with a valid report file' do
      before do
        allow(subject).to receive(:file_contents_as_json).and_return(file_contents_as_json)
      end

      it 'writes the file for the suite' do
        expect(File).to receive(:open)
          .with(File.join(described_class::DEFAULT_OPTIONS[:output_directory], "rspec_failed_tests.txt"), 'w').once
        expect(File).to receive(:open)
        .with(File.join(described_class::DEFAULT_OPTIONS[:output_directory], "rspec_ee_failed_tests.txt"), 'w').once

        subject.output_failed_tests
      end

      context 'when given a valid format' do
        subject { described_class.new(options.merge(format: :json)) }

        it 'writes the file for the suite' do
          expect(File).to receive(:open)
            .with(File.join(described_class::DEFAULT_OPTIONS[:output_directory], "rspec_failed_tests.json"), 'w').once
          expect(File).to receive(:open)
            .with(File.join(described_class::DEFAULT_OPTIONS[:output_directory], "rspec_ee_failed_tests.json"), 'w')
            .once

          subject.output_failed_tests
        end
      end

      context 'when given an invalid format' do
        subject { described_class.new(options.merge(format: :foo)) }

        it 'raises an exception' do
          expect { subject.output_failed_tests }
            .to raise_error '[FailedTests] Unsupported format `foo` (allowed formats: `oneline` and `json`)!'
        end
      end

      describe 'empty report' do
        let(:file_contents_as_json) do
          {}
        end

        it 'does not fail for output files' do
          subject.output_failed_tests
        end

        it 'returns empty results for suite failures' do
          result = subject.failed_cases_for_suite_collection

          expect(result.values.flatten).to be_empty
        end
      end
    end
  end

  describe 'missing report file' do
    subject { described_class.new(options.merge(previous_tests_report_path: 'unknownfile.json')) }

    it 'does not fail for output files' do
      subject.output_failed_tests
    end

    it 'returns empty results for suite failures' do
      result = subject.failed_cases_for_suite_collection

      expect(result.values.flatten).to be_empty
    end
  end
end
