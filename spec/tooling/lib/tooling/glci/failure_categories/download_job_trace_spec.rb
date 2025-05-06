# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require 'gitlab/rspec/stub_env'
require_relative '../../../../../../tooling/lib/tooling/glci/failure_categories/download_job_trace'

RSpec.describe Tooling::Glci::FailureCategories::DownloadJobTrace, feature_category: :tooling do
  include StubENV

  let(:api_url)       { 'https://gitlab.example.com/api/v4' }
  let(:project_id)    { '12345' }
  let(:job_id)        { '67890' }
  let(:access_token)  { 'fake_token' }
  let(:job_status)    { 'failed' }
  let(:trace_marker)  { 'failure-analyzer' }
  let(:trace_content_without_marker) { "This is the job trace content\nWith multiple lines\nOf output" }
  let(:trace_content_with_marker) do
    "#{trace_content_without_marker}\nsection_start:1234567890:#{trace_marker}\nReport failure category"
  end

  let(:output_file)   { 'test_trace.log' }
  let(:max_attempts)  { 3 }
  let(:retry_delay)   { 0.01 } # Use small delay in tests

  subject(:downloader) do
    described_class.new(
      api_url: api_url,
      project_id: project_id,
      job_id: job_id,
      access_token: access_token,
      job_status: job_status,
      trace_marker: trace_marker,
      max_attempts: max_attempts,
      retry_delay: retry_delay
    )
  end

  before do
    # Silence outputs to stdout by default
    allow(downloader).to receive(:puts)
    allow(downloader).to receive(:warn)

    # Clear all relevant environment variables to avoid external state influence
    stub_env('CI_API_V4_URL', nil)
    stub_env('CI_PROJECT_ID', nil)
    stub_env('CI_JOB_ID', nil)
    stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', nil)
    stub_env('CI_JOB_STATUS', nil)

    FileUtils.rm_f(output_file)
  end

  after do
    FileUtils.rm_f(output_file)
  end

  describe '#initialize parameter validation' do
    context 'when all required parameters are provided' do
      it 'initializes without error' do
        expect do
          described_class.new(
            api_url: api_url,
            project_id: project_id,
            job_id: job_id,
            access_token: access_token,
            job_status: job_status
          )
        end.not_to raise_error
      end
    end

    context 'when all required environment variables are set' do
      before do
        stub_env('CI_API_V4_URL', api_url)
        stub_env('CI_PROJECT_ID', project_id)
        stub_env('CI_JOB_ID', job_id)
        stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', access_token)
        stub_env('CI_JOB_STATUS', job_status)
      end

      it 'initializes without error' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context 'when api_url is missing' do
      before do
        stub_env('CI_API_V4_URL', nil)
      end

      it 'raises ArgumentError with appropriate message' do
        expect do
          described_class.new(
            project_id: project_id,
            job_id: job_id,
            access_token: access_token,
            job_status: job_status
          )
        end.to raise_error(ArgumentError, /Missing required parameters: api_url/)
      end
    end

    context 'when project_id is missing' do
      it 'raises ArgumentError with appropriate message' do
        expect do
          described_class.new(
            api_url: api_url,
            job_id: job_id,
            access_token: access_token,
            job_status: job_status
          )
        end.to raise_error(ArgumentError, /Missing required parameters: project_id/)
      end
    end

    context 'when job_id is missing' do
      it 'raises ArgumentError with appropriate message' do
        expect do
          described_class.new(
            api_url: api_url,
            project_id: project_id,
            access_token: access_token,
            job_status: job_status
          )
        end.to raise_error(ArgumentError, /Missing required parameters: job_id/)
      end
    end

    context 'when access_token is missing' do
      it 'raises ArgumentError with appropriate message' do
        expect do
          described_class.new(
            api_url: api_url,
            project_id: project_id,
            job_id: job_id,
            job_status: job_status
          )
        end.to raise_error(ArgumentError, /Missing required parameters: access_token/)
      end
    end

    context 'when job_status is missing' do
      it 'raises ArgumentError with appropriate message' do
        expect do
          described_class.new(
            api_url: api_url,
            project_id: project_id,
            job_id: job_id,
            access_token: access_token
          )
        end.to raise_error(ArgumentError, /Missing required parameters: job_status/)
      end
    end

    context 'when multiple parameters are missing' do
      it 'lists all missing parameters in the error message' do
        expect do
          described_class.new(
            job_id: job_id
          )
        end.to raise_error(ArgumentError, /Missing required parameters: api_url, project_id, access_token, job_status/)
      end
    end

    context 'when empty string is provided' do
      it 'treats empty strings as missing parameters' do
        expect do
          described_class.new(
            api_url: '',
            project_id: project_id,
            job_id: job_id,
            access_token: access_token,
            job_status: job_status
          )
        end.to raise_error(ArgumentError, /Missing required parameters: api_url/)
      end
    end
  end

  describe '#download' do
    shared_examples 'writes the expected trace to disk' do
      it 'writes the expected trace to disk' do
        expect(downloader.download(output_file: output_file)).to eq(output_file)
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq(expected_content)
      end
    end

    context 'when job status is failed' do
      context 'when we find the marker in the trace on first attempt' do
        before do
          stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
            .with(headers: { 'PRIVATE-TOKEN' => access_token })
            .to_return(status: 200, body: trace_content_with_marker)
        end

        let(:expected_content) { trace_content_with_marker }

        include_examples 'writes the expected trace to disk'

        it 'verifies the trace contains the marker' do
          allow(downloader).to receive(:puts).and_call_original

          expect { downloader.download(output_file: output_file) }
            .to output(/\[DownloadJobTrace\] Trace marker found/).to_stdout
        end

        it 'only attempts to download once' do
          expect(downloader).to receive(:fetch_trace).once.and_call_original

          downloader.download(output_file: output_file)

          expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace").once
        end
      end

      context 'when we do not find the marker in the trace on first attempt, but we find it on final attempt' do
        before do
          stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
            .with(headers: { 'PRIVATE-TOKEN' => access_token })
            .to_return({ status: 200, body: trace_content_without_marker },
              { status: 200, body: trace_content_without_marker },
              { status: 200, body: trace_content_with_marker })
        end

        let(:expected_content) { trace_content_with_marker }

        include_examples 'writes the expected trace to disk'

        it 'makes multiple requests until marker is found' do
          expect(downloader).to receive(:fetch_trace).exactly(3).times.and_call_original

          downloader.download(output_file: output_file)

          expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace").times(3)
        end
      end

      context 'when we do not find the marker after all attempts' do
        before do
          stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
            .with(headers: { 'PRIVATE-TOKEN' => access_token })
            .to_return(status: 200, body: trace_content_without_marker)
        end

        let(:expected_content) { trace_content_without_marker }

        include_examples 'writes the expected trace to disk'

        it 'makes max_attempts requests and gives a warning' do
          allow(downloader).to receive(:warn).and_call_original

          expect { downloader.download(output_file: output_file) }
            .to output(
              /\[DownloadJobTrace\] Could not verify we have the trace we need after #{max_attempts} attempts/
            ).to_stderr

          expect(WebMock).to have_requested(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
            .times(max_attempts)
        end
      end
    end

    context 'when job status is success' do
      let(:job_status) { 'success' }

      it 'skips downloading the trace file' do
        allow(downloader).to receive(:puts).and_call_original

        result = ""

        expect do
          result = downloader.download(output_file: output_file)
        end.to output(/\[DownloadJobTrace\] Job did not fail: exiting early/).to_stdout

        expect(result).to be_nil
        expect(File.exist?(output_file)).to be false
      end
    end

    context 'when the API request fails' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
          .with(headers: { 'PRIVATE-TOKEN' => access_token })
          .to_return(status: 403, body: 'Forbidden')
      end

      it 'raises an error' do
        expect { downloader.download(output_file: output_file) }.to raise_error(/Failed to download job trace/)
      end
    end

    context 'with environment variables' do
      let(:default_downloader) { described_class.new }

      before do
        stub_env('CI_API_V4_URL', api_url)
        stub_env('CI_PROJECT_ID', project_id)
        stub_env('CI_JOB_ID', job_id)
        stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', access_token)
        stub_env('CI_JOB_STATUS', job_status)

        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
          .with(headers: { 'PRIVATE-TOKEN' => access_token })
          .to_return(status: 200, body: trace_content_with_marker)

        # Silence outputs to stdout by default
        allow(default_downloader).to receive(:puts)
      end

      it 'uses environment variables when no parameters are provided' do
        expect(default_downloader.download(output_file: output_file)).to eq(output_file)
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq(trace_content_with_marker)
      end
    end

    context 'with custom trace marker' do
      let(:custom_marker) { 'CUSTOM_MARKER_12345' }
      let(:custom_trace_with_marker) { "#{trace_content_without_marker}\nCUSTOM_MARKER_12345\nEnd of trace" }

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
          .with(headers: { 'PRIVATE-TOKEN' => access_token })
          .to_return(status: 200, body: custom_trace_with_marker)
      end

      it 'verifies trace using the custom marker' do
        custom_downloader = described_class.new(
          api_url: api_url,
          project_id: project_id,
          job_id: job_id,
          access_token: access_token,
          job_status: job_status,
          trace_marker: custom_marker,
          max_attempts: max_attempts,
          retry_delay: retry_delay
        )

        # Silence outputs to stdout by default
        allow(custom_downloader).to receive(:puts)

        expect(custom_downloader.download(output_file: output_file)).to eq(output_file)
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq(custom_trace_with_marker)
      end
    end
  end

  describe 'trace verification' do
    context 'when trace is nil' do
      it 'does not have the marker' do
        expect(downloader.send(:has_marker?, nil)).to be false
      end
    end

    context 'when trace is empty' do
      it 'does not have the marker' do
        expect(downloader.send(:has_marker?, '')).to be false
      end
    end

    context 'when trace does not contain the marker' do
      it 'does not have the marker' do
        expect(downloader.send(:has_marker?, 'Some content without the marker')).to be false
      end
    end

    context 'when trace contains the marker' do
      it 'has the marker' do
        expect(downloader.send(:has_marker?,
          "Some content\nsection_start:1234567890:#{trace_marker}\nMore content")).to be true
      end
    end
  end
end
