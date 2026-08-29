# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../scripts/pipeline_test_report_builder'

RSpec.describe PipelineTestReportBuilder, feature_category: :tooling do
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

        context 'when a failed test build is allowed to fail' do
          let(:allowed_to_fail_build_id) { 8888 }
          let(:allowed_to_fail_build_uri) do
            "#{previous_pipeline_url}/tests/suite.json?build_ids[]=#{allowed_to_fail_build_id}"
          end

          let(:failed_builds_for_pipeline) do
            [
              { 'id' => allowed_to_fail_build_id, 'stage' => 'test', 'allow_failure' => true },
              { 'id' => failed_build_id, 'stage' => 'test', 'allow_failure' => false }
            ]
          end

          it 'only reports builds that block the pipeline', :aggregate_failures do
            expect(subject).not_to receive(:fetch).with(allowed_to_fail_build_uri)

            expected = {
              'suites' => [test_report_for_build.merge('job_url' => "/jobs/#{failed_build_id}")]
            }.to_json

            expect(subject.test_report_for_pipeline).to eq(expected)
          end
        end

        context 'when every failed test build is allowed to fail' do
          let(:failed_builds_for_pipeline) do
            [
              { 'id' => 8888, 'stage' => 'test', 'allow_failure' => true },
              { 'id' => 7777, 'stage' => 'test', 'allow_failure' => true }
            ]
          end

          it 'returns a hash with an empty "suites" array without fetching any report', :aggregate_failures do
            expect(subject).not_to receive(:test_report_for_build)

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

    context 'when rate limited (429)' do
      let(:uri_str) { 'https://gitlab.example.com/api/v4/test' }
      let(:parsed_response) { { 'data' => 'test' } }

      before do
        allow(subject).to receive(:sleep) # Don't actually sleep in tests
      end

      context 'when HTTP response is 429 Too Many Requests' do
        let(:http) { instance_double(Net::HTTP) }
        let(:success_response) do
          Net::HTTPSuccess.new('1.1', '200', 'OK').tap do |response|
            allow(response).to receive(:read_body).and_return(parsed_response.to_json)
          end
        end

        let(:rate_limit_response) do
          Net::HTTPTooManyRequests.new('1.1', '429', 'Too Many Requests').tap do |response|
            allow(response).to receive(:[]).and_return(nil)
          end
        end

        before do
          allow(Net::HTTP).to receive(:start).and_yield(http)
        end

        it 'detects 429 response and triggers retry logic', :aggregate_failures do
          call_count = 0

          allow(http).to receive(:request) do |_request, &block|
            call_count += 1
            if call_count == 1
              block.call(rate_limit_response)
            else
              block.call(success_response)
            end
          end

          result = subject.send(:fetch, uri_str)

          expect(result).to eq(parsed_response)
          expect(subject).to have_received(:sleep).once
        end

        it 'extracts Retry-After header from 429 response', :aggregate_failures do
          call_count = 0

          allow(rate_limit_response).to receive(:[]).with('Retry-After').and_return('30')
          allow(http).to receive(:request) do |_request, &block|
            call_count += 1
            if call_count == 1
              block.call(rate_limit_response)
            else
              block.call(success_response)
            end
          end

          subject.send(:fetch, uri_str)

          expect(subject).to have_received(:sleep).with(30)
        end
      end

      context 'when retry succeeds' do
        it 'retries with exponential backoff and returns the result', :aggregate_failures do
          call_count = 0

          allow(subject).to receive(:fetch).and_wrap_original do |_method, *args|
            call_count += 1
            if call_count == 1
              # First call - simulate the original fetch behavior that hits 429
              # We need to trigger handle_rate_limit which will call fetch again
              subject.send(:handle_rate_limit, args[0], 0)
            else
              # Subsequent calls succeed
              parsed_response
            end
          end

          result = subject.send(:fetch, uri_str)

          expect(result).to eq(parsed_response)
          expect(subject).to have_received(:sleep).with(2) # 2^(0+1) = 2
        end
      end

      context 'when all retries are exhausted' do
        let(:max_retries) { described_class::MAX_RETRIES }
        let(:error_pattern) { /Rate limited \(429\) after #{max_retries} retries/ }

        it 'raises a RateLimitError after MAX_RETRIES attempts' do
          # Simulate handle_rate_limit being called at max retries
          expect do
            subject.send(:handle_rate_limit, uri_str, max_retries)
          end.to raise_error(described_class::RateLimitError, error_pattern)
        end
      end

      context 'when retrying multiple times before success' do
        it 'uses exponential backoff timing', :aggregate_failures do
          call_count = 0

          allow(subject).to receive(:fetch).and_wrap_original do |_method, uri, **kwargs|
            retries = kwargs[:retries] || 0
            call_count += 1

            if retries < 2
              # First two attempts fail with rate limit
              subject.send(:handle_rate_limit, uri, retries)
            else
              # Third attempt succeeds
              parsed_response
            end
          end

          result = subject.send(:fetch, uri_str)

          expect(result).to eq(parsed_response)
          expect(subject).to have_received(:sleep).with(2).ordered # 2^1 = 2
          expect(subject).to have_received(:sleep).with(4).ordered # 2^2 = 4
        end
      end

      context 'when Retry-After header is present' do
        before do
          allow(subject).to receive(:fetch).and_return(parsed_response)
        end

        it 'uses Retry-After value when greater than exponential backoff', :aggregate_failures do
          retry_after_seconds = 10

          subject.send(:handle_rate_limit, uri_str, 0, retry_after_seconds)

          expect(subject).to have_received(:sleep).with(retry_after_seconds)
        end

        it 'uses exponential backoff when greater than Retry-After', :aggregate_failures do
          retry_after_seconds = 1

          subject.send(:handle_rate_limit, uri_str, 0, retry_after_seconds)

          expect(subject).to have_received(:sleep).with(2) # 2^(0+1) = 2 > 1
        end

        it 'handles nil Retry-After gracefully' do
          subject.send(:handle_rate_limit, uri_str, 0, nil)

          expect(subject).to have_received(:sleep).with(2)
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

  describe '#execute' do
    before do
      allow(FileUtils).to receive(:mkdir_p)
    end

    it 'writes the report to the output file' do
      allow(subject).to receive(:test_report_for_pipeline).and_return('{"suites":[]}')

      expect(File).to receive(:open).with(output_file_path, 'w').and_yield(file = instance_double(File))
      expect(file).to receive(:write).with('{"suites":[]}')

      subject.execute
    end

    context 'when the report fetch is rate limited past MAX_RETRIES' do
      before do
        allow(subject).to receive(:test_report_for_pipeline)
          .and_raise(described_class::RateLimitError, 'Rate limited (429) after 3 retries')
      end

      it 'writes an empty report and does not raise' do
        expect(File).to receive(:open).with(output_file_path, 'w').and_yield(file = instance_double(File))
        expect(file).to receive(:write).with('{}')

        expect { subject.execute }.not_to raise_error
      end
    end
  end
end
