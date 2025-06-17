# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/failed_tests'

RSpec.describe FailedTests do
  let(:report_file) { 'spec/fixtures/scripts/test_report.json' }
  let(:options) { described_class::DEFAULT_OPTIONS.merge(previous_tests_report_path: report_file) }
  let(:failure_path) { 'path/to/fail_file_spec.rb' }
  let(:other_failure_path) { 'path/to/fail_file_spec_2.rb' }
  let(:output_directory) { described_class::DEFAULT_OPTIONS[:output_directory] }
  let(:user_spec) { 'spec/models/user_spec.rb' }
  let(:project_spec) { 'spec/models/project_spec.rb' }
  let(:issue_spec) { 'spec/models/issue_spec.rb' }
  let(:file_contents_as_json) do
    {
      'suites' => [
        {
          'failed_count' => 1,
          'name' => 'rspec unit pg16 10/12',
          'test_cases' => [
            {
              'status' => 'failed',
              'file' => failure_path
            }
          ]
        },
        {
          'failed_count' => 1,
          'name' => 'rspec-ee unit pg16',
          'test_cases' => [
            {
              'status' => 'failed',
              'file' => failure_path
            }
          ]
        },
        {
          'failed_count' => 1,
          'name' => 'rspec unit pg16 10/12',
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

  def failed_test_case(file_path)
    { 'status' => 'failed', 'file' => file_path, 'job_url' => nil }
  end

  describe '#output_failed_tests' do
    context 'with a valid report file' do
      before do
        allow(subject).to receive(:file_contents_as_json).and_return(file_contents_as_json)
      end

      it 'writes the file for the suite' do
        expect(File).to receive(:write)
          .with(File.join(output_directory, "rspec_failed_tests.txt"),
            "#{failure_path} #{other_failure_path}")
        expect(File).to receive(:write)
          .with(File.join(output_directory, "rspec_ee_failed_tests.txt"),
            failure_path)

        subject.output_failed_tests
      end

      context 'with single_output enabled' do
        subject { described_class.new(options.merge(single_output: true)) }

        it 'writes only the consolidated file' do
          expect(File).to receive(:write)
            .with(File.join(output_directory, "rspec_all_failed_tests.txt"),
              "#{failure_path} #{other_failure_path}")

          subject.output_failed_tests
        end
      end

      context 'when given a valid format' do
        subject { described_class.new(options.merge(format: :json)) }

        it 'writes the file for the suite' do
          expected_rspec_content = Gitlab::Json.pretty_generate([
            { 'status' => 'failed', 'file' => failure_path, 'job_url' => nil },
            { 'status' => 'failed', 'file' => other_failure_path, 'job_url' => nil }
          ])
          expected_rspec_ee_content = Gitlab::Json.pretty_generate([
            { 'status' => 'failed', 'file' => failure_path, 'job_url' => nil }
          ])

          expect(File).to receive(:write)
            .with(File.join(output_directory, "rspec_failed_tests.json"),
              expected_rspec_content)
          expect(File).to receive(:write)
            .with(File.join(output_directory, "rspec_ee_failed_tests.json"),
              expected_rspec_ee_content)

          subject.output_failed_tests
        end

        context 'with single_output enabled' do
          subject { described_class.new(options.merge(format: :json, single_output: true)) }

          it 'writes consolidated json file' do
            expected_content = Gitlab::Json.pretty_generate([
              { 'status' => 'failed', 'file' => failure_path, 'job_url' => nil },
              { 'status' => 'failed', 'file' => failure_path, 'job_url' => nil },
              { 'status' => 'failed', 'file' => other_failure_path, 'job_url' => nil }
            ])

            expect(File).to receive(:write)
              .with(File.join(output_directory, "rspec_all_failed_tests.json"),
                expected_content)

            subject.output_failed_tests
          end
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

  describe 'deduplication behavior' do
    let(:duplicate_failures_json) do
      {
        'suites' => [
          {
            'failed_count' => 2,
            'name' => 'rspec unit pg16 1/12',
            'test_cases' => [
              { 'status' => 'failed', 'file' => user_spec },
              { 'status' => 'failed', 'file' => project_spec }
            ]
          },
          {
            'failed_count' => 2,
            'name' => 'rspec-ee unit pg16 2/12',
            'test_cases' => [
              { 'status' => 'failed', 'file' => user_spec },
              { 'status' => 'failed', 'file' => issue_spec }
            ]
          }
        ]
      }
    end

    context 'with single_output enabled and duplicate files across suites' do
      subject { described_class.new(options.merge(single_output: true)) }

      before do
        allow(subject).to receive(:file_contents_as_json).and_return(duplicate_failures_json)
        allow(File).to receive(:write)
      end

      it 'deduplicates file paths in oneline format' do
        expect(File).to receive(:write)
          .with(File.join(output_directory, "rspec_all_failed_tests.txt"),
            "#{user_spec} #{project_spec} #{issue_spec}")

        subject.output_failed_tests
      end
    end
  end

  describe 'CLI option parsing' do
    describe '.parse_cli_options' do
      it 'parses all options when provided' do
        options = described_class.parse_cli_options([
          '--previous-tests-report-path', '/custom/report.json',
          '--output-directory', '/custom/output',
          '--format', 'json',
          '--rspec-pg-regex', 'custom.*pg',
          '--rspec-ee-pg-regex', 'custom.*ee',
          '--single-output'
        ])

        expect(options[:previous_tests_report_path]).to eq '/custom/report.json'
        expect(options[:output_directory]).to eq '/custom/output'
        expect(options[:format]).to eq 'json'
        expect(options[:rspec_pg_regex]).to eq(/custom.*pg/)
        expect(options[:rspec_ee_pg_regex]).to eq(/custom.*ee/)
        expect(options[:single_output]).to be true
      end

      it 'uses default values when no options provided' do
        options = described_class.parse_cli_options([])

        expect(options[:previous_tests_report_path]).to eq 'test_results/previous/test_reports.json'
        expect(options[:output_directory]).to eq 'tmp/previous_failed_tests/'
        expect(options[:format]).to eq :oneline
        expect(options[:rspec_pg_regex]).to eq(/rspec .+ pg16( .+)?/)
        expect(options[:rspec_ee_pg_regex]).to eq(/rspec-ee .+ pg16( .+)?/)
        expect(options[:single_output]).to be false
      end

      it 'handles help option by exiting' do
        expect { described_class.parse_cli_options(['--help']) }.to raise_error(SystemExit)
      end
    end
  end
end
