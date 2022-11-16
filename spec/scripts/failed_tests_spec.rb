# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/failed_tests'

RSpec.describe FailedTests do
  let(:report_file) { 'spec/fixtures/scripts/test_report.json' }
  let(:output_directory) { 'tmp/previous_test_results' }
  let(:rspec_pg_regex) { /rspec .+ pg12( .+)?/ }
  let(:rspec_ee_pg_regex) { /rspec-ee .+ pg12( .+)?/ }

  subject { described_class.new(previous_tests_report_path: report_file, output_directory: output_directory, rspec_pg_regex: rspec_pg_regex, rspec_ee_pg_regex: rspec_ee_pg_regex) }

  describe '#output_failed_test_files' do
    it 'writes the file for the suite' do
      expect(File).to receive(:open).with(File.join(output_directory, "rspec_failed_files.txt"), 'w').once

      subject.output_failed_test_files
    end
  end

  describe '#failed_files_for_suite_collection' do
    let(:failure_path) { 'path/to/fail_file_spec.rb' }
    let(:other_failure_path) { 'path/to/fail_file_spec_2.rb' }
    let(:file_contents_as_json) do
      {
        'suites' => [
          {
            'failed_count' => 1,
            'name' => 'rspec unit pg12 10/12',
            'test_cases' => [
              {
                'status' => 'failed',
                'file' => failure_path
              }
            ]
          },
          {
            'failed_count' => 1,
            'name' => 'rspec-ee unit pg12',
            'test_cases' => [
              {
                'status' => 'failed',
                'file' => failure_path
              }
            ]
          },
          {
            'failed_count' => 1,
            'name' => 'rspec unit pg13 10/12',
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

    before do
      allow(subject).to receive(:file_contents_as_json).and_return(file_contents_as_json)
    end

    it 'returns a list of failed file paths for suite collection' do
      result = subject.failed_files_for_suite_collection

      expect(result[:rspec].to_a).to match_array(failure_path)
      expect(result[:rspec_ee].to_a).to match_array(failure_path)
    end
  end

  describe 'empty report' do
    let(:file_content) do
      '{}'
    end

    before do
      allow(subject).to receive(:file_contents).and_return(file_content)
    end

    it 'does not fail for output files' do
      subject.output_failed_test_files
    end

    it 'returns empty results for suite failures' do
      result = subject.failed_files_for_suite_collection

      expect(result.values.flatten).to be_empty
    end
  end

  describe 'invalid report' do
    let(:file_content) do
      ''
    end

    before do
      allow(subject).to receive(:file_contents).and_return(file_content)
    end

    it 'does not fail for output files' do
      subject.output_failed_test_files
    end

    it 'returns empty results for suite failures' do
      result = subject.failed_files_for_suite_collection

      expect(result.values.flatten).to be_empty
    end
  end

  describe 'missing report file' do
    let(:report_file) { 'unknownfile.json' }

    it 'does not fail for output files' do
      subject.output_failed_test_files
    end

    it 'returns empty results for suite failures' do
      result = subject.failed_files_for_suite_collection

      expect(result.values.flatten).to be_empty
    end
  end
end
