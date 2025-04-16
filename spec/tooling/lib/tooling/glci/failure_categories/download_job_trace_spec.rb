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
  let(:trace_content) { "This is the job trace content\nWith multiple lines\nOf output" }
  let(:output_file)   { 'test_trace.log' }

  subject(:downloader) do
    described_class.new(
      api_url: api_url,
      project_id: project_id,
      job_id: job_id,
      access_token: access_token,
      job_status: job_status
    )
  end

  before do
    # Clear all relevant environment variables to avoid external state influence
    stub_env('CI_API_V4_URL', nil)
    stub_env('CI_PROJECT_ID', nil)
    stub_env('CI_JOB_ID', nil)
    stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', nil)
    stub_env('CI_JOB_STATUS', nil)

    stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/trace")
      .with(headers: { 'PRIVATE-TOKEN' => access_token })
      .to_return(status: 200, body: trace_content)

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
    context 'when job status is failed' do
      it 'downloads the trace file' do
        expect(downloader.download(output_file: output_file)).to eq(output_file)
        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq(trace_content)
      end
    end

    context 'when job status is success' do
      let(:job_status) { 'success' }

      it 'skips downloading the trace file' do
        result = ""

        expect do
          result = downloader.download(output_file: output_file)
        end.to output("[DownloadJobTrace] Job did not fail: exiting early (status: success)\n").to_stdout

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
      before do
        stub_env('CI_API_V4_URL', api_url)
        stub_env('CI_PROJECT_ID', project_id)
        stub_env('CI_JOB_ID', job_id)
        stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', access_token)
        stub_env('CI_JOB_STATUS', job_status)
      end

      let(:default_downloader) { described_class.new }

      it 'uses environment variables when no parameters are provided' do
        expect(default_downloader.download(output_file: output_file)).to eq(output_file)
        expect(File.exist?(output_file)).to be true
        expect(File.read(output_file)).to eq(trace_content)
      end
    end
  end
end
