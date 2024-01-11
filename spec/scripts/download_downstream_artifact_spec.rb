# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/all'
require_relative '../../scripts/download-downstream-artifact'

# rubocop:disable RSpec/VerifiedDoubles -- doubles are simple mocks of a few methods from external code

RSpec.describe DownloadDownstreamArtifact, feature_category: :tooling do
  include StubENV

  subject(:execute) { described_class.new(options).execute }

  before do
    stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', nil)
    stub_env('CI_PROJECT_ID', nil)
    stub_env('CI_PIPELINE_ID', nil)
    stub_env('CI_API_V4_URL', nil)
    stub_env('DOWNSTREAM_PROJECT', nil)
    stub_env('DOWNSTREAM_JOB_NAME', nil)
    stub_env('TRIGGER_JOB_NAME', nil)
    stub_env('DOWNSTREAM_JOB_ARTIFACT_PATH', nil)
    stub_env('OUTPUT_ARTIFACT_PATH', nil)
  end

  describe '#execute' do
    let(:options) do
      {
        api_token: 'asdf1234',
        endpoint: 'https://gitlab.com/api/v4',
        upstream_project: 'upstream/project',
        upstream_pipeline_id: 123,
        downstream_project: 'downstream/project',
        downstream_job_name: 'test-job',
        trigger_job_name: 'trigger-job',
        downstream_artifact_path: 'scores-DOWNSTREAM_JOB_ID.csv',
        output_artifact_path: 'scores.csv'
      }
    end

    let(:client) { double('Gitlab::Client') }
    let(:artifact_response) { double('io', read: 'artifact content') }

    let(:job) do
      Struct.new(:id, :name, :web_url).new(789, 'test-job', 'https://example.com/jobs/789')
    end

    let(:downstream_pipeline) do
      Struct.new(:id, :web_url).new(111, 'https://example.com/pipelines/111')
    end

    let(:pipeline_bridges) do
      double('pipeline_bridges', auto_paginate: [double(name: 'trigger-job', downstream_pipeline: downstream_pipeline)])
    end

    let(:expected_output) do
      <<~OUTPUT
        Fetching scores artifact from downstream pipeline triggered via trigger-job...
        Downstream pipeline is https://example.com/pipelines/111.
        Downstream job "test-job": https://example.com/jobs/789.
        Fetching artifact "scores-789.csv" from test-job...
        Artifact saved as scores.csv ...
      OUTPUT
    end

    before do
      allow(Gitlab).to receive(:client)
        .with(endpoint: options[:endpoint], private_token: options[:api_token])
        .and_return(client)

      allow(client).to receive(:pipeline_bridges).and_return(pipeline_bridges)
      allow(client).to receive(:pipeline).and_return(downstream_pipeline)
      allow(client).to receive(:pipeline_jobs).and_return([job])
      allow(client).to receive(:download_job_artifact_file).and_return(artifact_response)
      allow(File).to receive(:write)
    end

    it 'downloads artifact from downstream pipeline' do
      expect(client).to receive(:download_job_artifact_file).with('downstream/project', 789, 'scores-789.csv')

      expect { execute }.to output(expected_output).to_stdout
    end

    it 'saves artifact to output path' do
      expect(File).to receive(:write).with('scores.csv', 'artifact content')

      expect { execute }.to output(expected_output).to_stdout
    end

    context 'when options come from environment variables' do
      before do
        stub_env('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE', 'asdf1234')
        stub_env('CI_PROJECT_ID', 'upstream/project')
        stub_env('CI_PIPELINE_ID', '123')
        stub_env('CI_API_V4_URL', 'https://gitlab.com/api/v4')
        stub_env('DOWNSTREAM_PROJECT', 'downstream/project')
        stub_env('DOWNSTREAM_JOB_NAME', 'test-job')
        stub_env('TRIGGER_JOB_NAME', 'trigger-job')
        stub_env('DOWNSTREAM_JOB_ARTIFACT_PATH', 'scores-DOWNSTREAM_JOB_ID.csv')
        stub_env('OUTPUT_ARTIFACT_PATH', 'scores.csv')

        stub_const('API::DEFAULT_OPTIONS', {
          project: ENV['CI_PROJECT_ID'],
          pipeline_id: ENV['CI_PIPELINE_ID'],
          api_token: ENV['PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE'],
          endpoint: ENV['CI_API_V4_URL']
        })
      end

      it 'uses the environment variable values' do
        options = described_class.options_from_env

        expect(File).to receive(:write)
        expect { described_class.new(options).execute }.to output(expected_output).to_stdout
      end
    end

    context 'when the downstream pipeline cannot be found' do
      let(:pipeline_bridges) do
        double('pipeline_bridges', auto_paginate: [double(name: 'trigger-job', downstream_pipeline: nil)])
      end

      it 'aborts' do
        expect(File).not_to receive(:write)
        expect { described_class.new(options).execute }
          .to output(
            %r{Could not find downstream pipeline triggered via trigger-job in project downstream/project}
          ).to_stderr
          .and raise_error(SystemExit)
      end
    end

    context 'when the downstream job cannot be found' do
      let(:job) { double('job', name: 'foo') }

      it 'aborts' do
        expect(File).not_to receive(:write)
        expect { described_class.new(options).execute }
          .to output(
            %r{Could not find job with name 'test-job' in https://example.com/pipelines/111}
          ).to_stderr
          .and raise_error(SystemExit)
      end
    end

    context 'when the downstream artifact cannot be found' do
      let(:artifact_response) { 'error' }

      it 'aborts' do
        expect(File).not_to receive(:write)
        expect { described_class.new(options).execute }
          .to output(
            %r{Could not download artifact. Request returned: error}
          ).to_stderr
          .and raise_error(SystemExit)
      end
    end
  end

  context 'when called without an API token' do
    let(:options) do
      {
        endpoint: 'https://gitlab.com/api/v4',
        upstream_project: 'upstream/project',
        upstream_pipeline_id: 123,
        downstream_project: 'downstream/project',
        downstream_job_name: 'test-job',
        trigger_job_name: 'trigger-job',
        downstream_artifact_path: 'scores-DOWNSTREAM_JOB_ID.csv',
        output_artifact_path: 'scores.csv'
      }
    end

    it 'raises an error' do
      expect { described_class.new(options) }.to raise_error(ArgumentError)
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
