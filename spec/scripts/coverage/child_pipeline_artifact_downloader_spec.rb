# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require_relative '../../../scripts/coverage/child_pipeline_artifact_downloader'

RSpec.describe ChildPipelineArtifactDownloader, feature_category: :tooling do
  let(:api_url) { 'https://gitlab.example.com/api/v4' }
  let(:project_id) { '12345' }
  let(:pipeline_id) { '67890' }
  let(:job_token) { 'token123' }

  let(:bridge_name) { 'e2e:test-on-gdk' }
  let(:job_name) { 'process-backend-coverage' }
  let(:coverage_type) { 'backend' }

  let(:env_vars) do
    {
      'CI_API_V4_URL' => api_url,
      'CI_PROJECT_ID' => project_id,
      'CI_PIPELINE_ID' => pipeline_id,
      'CI_JOB_TOKEN' => job_token
    }
  end

  before do
    stub_const('ENV', env_vars)
  end

  describe '#initialize' do
    it 'stores the bridge_name, job_name, and coverage_type' do
      downloader = described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)

      expect(downloader.instance_variable_get(:@bridge_name)).to eq(bridge_name)
      expect(downloader.instance_variable_get(:@job_name)).to eq(job_name)
      expect(downloader.instance_variable_get(:@coverage_type)).to eq(coverage_type)
    end

    it 'fetches environment variables' do
      downloader = described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)

      expect(downloader.instance_variable_get(:@api_url)).to eq(api_url)
      expect(downloader.instance_variable_get(:@project_id)).to eq(project_id)
      expect(downloader.instance_variable_get(:@pipeline_id)).to eq(pipeline_id)
      expect(downloader.instance_variable_get(:@job_token)).to eq(job_token)
    end

    context 'when required environment variables are missing' do
      let(:env_vars) { {} }

      it 'raises KeyError' do
        expect do
          described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)
        end.to raise_error(KeyError)
      end
    end
  end

  describe '#run' do
    subject(:downloader) do
      described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)
    end

    let(:child_pipeline_id) { 11111 }
    let(:job_id) { 22222 }

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when child pipeline and job are found' do
      let(:bridges_response) do
        [{ 'name' => bridge_name, 'downstream_pipeline' => { 'id' => child_pipeline_id } }].to_json
      end

      let(:jobs_response) do
        [{ 'name' => job_name, 'id' => job_id }].to_json
      end

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: bridges_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{child_pipeline_id}/jobs")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: jobs_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake zip content')

        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)
      end

      it 'downloads and extracts artifacts' do
        expect(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)

        downloader.run
      end

      it 'returns true on success' do
        expect(downloader.run).to be true
      end
    end

    context 'when child pipeline is not found' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: '[]')
      end

      it 'returns false' do
        expect(downloader.run).to be false
      end
    end

    context 'when job is not found in child pipeline' do
      let(:bridges_response) do
        [{ 'name' => bridge_name, 'downstream_pipeline' => { 'id' => child_pipeline_id } }].to_json
      end

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: bridges_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{child_pipeline_id}/jobs")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: '[]')
      end

      it 'returns false' do
        expect(downloader.run).to be false
      end
    end

    context 'when artifact download requires redirect (GCS)' do
      let(:bridges_response) do
        [{ 'name' => bridge_name, 'downstream_pipeline' => { 'id' => child_pipeline_id } }].to_json
      end

      let(:jobs_response) do
        [{ 'name' => job_name, 'id' => job_id }].to_json
      end

      let(:gcs_url) { 'https://storage.googleapis.com/gitlab-artifacts/test.zip' }

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: bridges_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{child_pipeline_id}/jobs")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: jobs_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 302, headers: { 'Location' => gcs_url })

        stub_request(:get, gcs_url)
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake zip content')

        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)
      end

      it 'follows the redirect and downloads artifacts' do
        expect(downloader.run).to be true
      end
    end

    context 'with frontend coverage configuration' do
      subject(:downloader) do
        described_class.new(
          bridge_name: 'e2e:test-on-gdk',
          job_name: 'process-frontend-coverage',
          coverage_type: 'frontend'
        )
      end

      let(:bridges_response) do
        [{ 'name' => 'e2e:test-on-gdk', 'downstream_pipeline' => { 'id' => child_pipeline_id } }].to_json
      end

      let(:jobs_response) do
        [{ 'name' => 'process-frontend-coverage', 'id' => job_id }].to_json
      end

      before do
        allow(downloader).to receive(:puts)

        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: bridges_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{child_pipeline_id}/jobs")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: jobs_response)

        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .with(headers: { 'JOB-TOKEN' => job_token })
          .to_return(status: 200, body: 'fake zip content')

        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)
      end

      it 'downloads frontend coverage artifacts' do
        expect(downloader.run).to be true
      end
    end
  end

  describe '#find_child_pipeline_id (private)' do
    subject(:downloader) do
      described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)
    end

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when bridge exists with downstream pipeline' do
      let(:bridges_response) do
        [{ 'name' => bridge_name, 'downstream_pipeline' => { 'id' => 11111 } }].to_json
      end

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .to_return(status: 200, body: bridges_response)
      end

      it 'returns the child pipeline ID' do
        result = downloader.send(:find_child_pipeline_id)

        expect(result).to eq(11111)
      end
    end

    context 'when bridge is not found' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .to_return(status: 200, body: '[]')
      end

      it 'returns nil' do
        result = downloader.send(:find_child_pipeline_id)

        expect(result).to be_nil
      end
    end

    context 'when bridge exists but has no downstream pipeline' do
      let(:bridges_response) do
        [{ 'name' => bridge_name, 'downstream_pipeline' => nil }].to_json
      end

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/#{pipeline_id}/bridges")
          .to_return(status: 200, body: bridges_response)
      end

      it 'returns nil' do
        result = downloader.send(:find_child_pipeline_id)

        expect(result).to be_nil
      end
    end
  end

  describe '#find_job_id (private)' do
    subject(:downloader) do
      described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)
    end

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when job exists' do
      let(:jobs_response) do
        [{ 'name' => job_name, 'id' => 22222 }].to_json
      end

      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/11111/jobs")
          .to_return(status: 200, body: jobs_response)
      end

      it 'returns the job ID' do
        result = downloader.send(:find_job_id, 11111)

        expect(result).to eq(22222)
      end
    end

    context 'when job is not found' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/pipelines/11111/jobs")
          .to_return(status: 200, body: '[]')
      end

      it 'returns nil' do
        result = downloader.send(:find_job_id, 11111)

        expect(result).to be_nil
      end
    end
  end

  describe '#download_artifacts (private)' do
    subject(:downloader) do
      described_class.new(bridge_name: bridge_name, job_name: job_name, coverage_type: coverage_type)
    end

    let(:job_id) { 22222 }

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when download and extraction succeed' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .to_return(status: 200, body: 'fake zip content')

        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)
      end

      it 'downloads and extracts artifacts' do
        expect(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)

        downloader.send(:download_artifacts, job_id)
      end
    end

    context 'when extraction fails' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .to_return(status: 200, body: 'fake zip content')

        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(false)
      end

      it 'raises an error' do
        expect { downloader.send(:download_artifacts, job_id) }.to raise_error(RuntimeError, /Failed to extract/)
      end
    end

    context 'when download fails' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .to_return(status: 404, body: 'Not Found')
      end

      it 'raises an error' do
        expect { downloader.send(:download_artifacts, job_id) }.to raise_error(RuntimeError, /Failed to download/)
      end
    end

    context 'when too many redirects' do
      before do
        stub_request(:get, "#{api_url}/projects/#{project_id}/jobs/#{job_id}/artifacts")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redirect1" })

        stub_request(:get, "#{api_url}/redirect1")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redirect2" })

        stub_request(:get, "#{api_url}/redirect2")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redirect3" })

        stub_request(:get, "#{api_url}/redirect3")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redirect4" })

        stub_request(:get, "#{api_url}/redirect4")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redirect5" })

        stub_request(:get, "#{api_url}/redirect5")
          .to_return(status: 302, headers: { 'Location' => "#{api_url}/redirect6" })
      end

      it 'raises an error after 5 redirects' do
        expect { downloader.send(:download_artifacts, job_id) }.to raise_error(RuntimeError, /Too many redirects/)
      end
    end
  end
end
