# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/pipeline_test_report_builder'

RSpec.describe PipelineTestReportBuilder, feature_category: :tooling do
  let(:report_file) { 'spec/fixtures/scripts/test_report.json' }
  let(:output_file_path) { 'tmp/previous_test_results/output_file.json' }
  let(:options) do
    described_class::DEFAULT_OPTIONS.merge(
      target_project: 'gitlab-org/gitlab',
      current_pipeline_id: '42',
      mr_id: '999',
      instance_base_url: 'https://gitlab.com',
      output_file_path: output_file_path
    )
  end

  let(:previous_pipeline_url) { '/pipelines/previous' }

  let(:previous_pipeline) do
    {
      'status' => 'failed',
      'id' => 1,
      'web_url' => previous_pipeline_url
    }
  end

  let(:latest_pipeline_url) { '/pipelines/latest' }

  let(:latest_pipeline) do
    {
      'status' => 'running',
      'id' => 3,
      'web_url' => latest_pipeline_url
    }
  end

  let(:mr_pipelines) { [latest_pipeline, previous_pipeline] }

  let(:failed_build_id) { 9999 }

  let(:failed_builds_for_pipeline) do
    [
      {
        'id' => failed_build_id,
        'stage' => 'test'
      }
    ]
  end

  let(:test_report_for_build) do
    {
      name: "rspec-ee system pg11 geo",
      failed_count: 41,
      test_cases: [
        {
          status: "failed",
          name: "example",
          classname: "ee.spec.features.geo_node_spec",
          file: "./ee/spec/features/geo_node_spec.rb",
          execution_time: 6.324748,
          system_output: {
            __content__: "\n",
            message: "RSpec::Core::MultipleExceptionError",
            type: "RSpec::Core::MultipleExceptionError"
          }
        }
      ]
    }
  end

  subject { described_class.new(options) }

  before do
    allow(subject).to receive(:pipelines_for_mr).and_return(mr_pipelines)
    allow(subject).to receive(:failed_builds_for_pipeline).and_return(failed_builds_for_pipeline)
  end

  describe '#previous_pipeline' do
    let(:fork_pipeline_url) { 'fork_pipeline_url' }
    let(:fork_pipeline) do
      {
        'status' => 'failed',
        'id' => 2,
        'web_url' => fork_pipeline_url
      }
    end

    before do
      allow(subject).to receive(:test_report_for_build).and_return(test_report_for_build)
    end

    context 'pipeline in a fork project' do
      let(:mr_pipelines) { [latest_pipeline, fork_pipeline] }

      it 'returns fork pipeline' do
        expect(subject.previous_pipeline).to eq(fork_pipeline)
      end
    end

    context 'pipeline in target project' do
      it 'returns failed pipeline' do
        expect(subject.previous_pipeline).to eq(previous_pipeline)
      end
    end
  end

  describe '#test_report_for_pipeline' do
    context 'for previous pipeline' do
      let(:failed_build_uri) { "#{previous_pipeline_url}/tests/suite.json?build_ids[]=#{failed_build_id}" }

      before do
        allow(subject).to receive(:fetch).with(failed_build_uri).and_return(test_report_for_build)
      end

      it 'fetches builds from pipeline related to MR' do
        expected = { "suites" => [test_report_for_build.merge('job_url' => "/jobs/#{failed_build_id}")] }.to_json
        expect(subject.test_report_for_pipeline).to eq(expected)
      end

      context 'canonical pipeline' do
        context 'no previous pipeline' do
          let(:mr_pipelines) { [] }

          it 'returns empty hash' do
            expect(subject.test_report_for_pipeline).to eq("{}")
          end
        end

        context 'no failed test builds' do
          let(:failed_builds_for_pipeline) do
            [
              {
                'id' => 9999,
                'stage' => 'prepare'
              }
            ]
          end

          it 'returns a hash with an empty "suites" array' do
            expect(subject.test_report_for_pipeline).to eq({ suites: [] }.to_json)
          end
        end

        context 'failed pipeline and failed test builds' do
          before do
            allow(subject).to receive(:fetch).with(failed_build_uri).and_return(test_report_for_build)
          end

          it 'returns populated test list for suites' do
            actual = subject.test_report_for_pipeline
            expected = {
              'suites' => [test_report_for_build]
            }.to_json

            expect(actual).to eq(expected)
          end
        end

        context 'when receiving a server error' do
          let(:response) { instance_double('Net::HTTPResponse') }
          let(:error) { Net::HTTPClientException.new('server error', response) }
          let(:test_report_for_pipeline) { subject.test_report_for_pipeline }

          before do
            allow(response).to receive(:code).and_return(response_code)
            allow(subject).to receive(:fetch).with(failed_build_uri).and_raise(error)
          end

          context 'when response code is 404' do
            let(:response_code) { 404 }

            it 'continues without the missing reports' do
              expected = { suites: [] }.to_json

              expect { test_report_for_pipeline }.not_to raise_error
              expect(test_report_for_pipeline).to eq(expected)
            end
          end

          context 'when response code is unexpected' do
            let(:response_code) { 500 }

            it 'raises HTTPServerException' do
              expect { test_report_for_pipeline }.to raise_error(error)
            end
          end
        end
      end
    end

    context 'for latest pipeline' do
      let(:failed_build_uri) { "#{latest_pipeline_url}/tests/suite.json?build_ids[]=#{failed_build_id}" }
      let(:current_pipeline_uri) do
        "#{options[:api_endpoint]}/projects/#{options[:target_project]}/pipelines/#{options[:current_pipeline_id]}"
      end

      subject { described_class.new(options.merge(pipeline_index: :latest)) }

      it 'fetches builds from pipeline related to MR' do
        expect(subject).to receive(:fetch).with(current_pipeline_uri).and_return(mr_pipelines[0])
        expect(subject).to receive(:fetch).with(failed_build_uri).and_return(test_report_for_build)

        subject.test_report_for_pipeline
      end
    end
  end
end
