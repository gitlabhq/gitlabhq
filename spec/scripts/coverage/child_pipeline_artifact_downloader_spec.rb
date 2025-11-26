# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../scripts/coverage/download_e2e_coverage_from_child_pipeline'

# rubocop:disable RSpec/VerifiedDoubles -- Gitlab::Client and response objects not loaded in fast_spec_helper
RSpec.describe ChildPipelineArtifactDownloader, feature_category: :tooling do
  let(:api_url) { 'https://gitlab.example.com/api/v4' }
  let(:project_id) { '12345' }
  let(:pipeline_id) { '67890' }
  let(:job_token) { 'token123' }
  let(:client) { double('Gitlab::Client') }

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
    allow(Gitlab).to receive(:client).and_return(client)
  end

  describe '#initialize' do
    it 'creates a Gitlab client with correct parameters' do
      expect(Gitlab).to receive(:client).with(
        endpoint: api_url,
        private_token: job_token
      )

      described_class.new
    end

    context 'when required environment variables are missing' do
      let(:env_vars) { {} }

      it 'raises KeyError' do
        expect { described_class.new }.to raise_error(KeyError)
      end
    end
  end

  describe '#run' do
    subject(:downloader) { described_class.new }

    let(:child_pipeline_id) { 11111 }
    let(:job_id) { 22222 }

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when child pipeline and job are found' do
      let(:bridge) { double(name: 'e2e:test-on-gdk', downstream_pipeline: double(id: child_pipeline_id)) }
      let(:job) { double(name: 'process-backend-coverage', id: job_id) }
      let(:bridges_paginator) { double(auto_paginate: [bridge]) }
      let(:jobs_paginator) { double(auto_paginate: [job]) }

      before do
        allow(client).to receive_messages(
          pipeline_bridges: bridges_paginator,
          pipeline_jobs: jobs_paginator,
          download_job_artifact_file: 'artifact data'
        )
        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)
      end

      it 'downloads and extracts artifacts' do
        expect(client).to receive(:download_job_artifact_file).with(project_id, job_id)

        downloader.run
      end
    end

    context 'when child pipeline is not found' do
      let(:bridges_paginator) { double(auto_paginate: []) }

      before do
        allow(client).to receive(:pipeline_bridges).and_return(bridges_paginator)
      end

      it 'returns early without downloading' do
        expect(client).not_to receive(:pipeline_jobs)
        expect(client).not_to receive(:download_job_artifact_file)

        downloader.run
      end
    end

    context 'when job is not found in child pipeline' do
      let(:bridge) { double(name: 'e2e:test-on-gdk', downstream_pipeline: double(id: child_pipeline_id)) }
      let(:bridges_paginator) { double(auto_paginate: [bridge]) }
      let(:jobs_paginator) { double(auto_paginate: []) }

      before do
        allow(client).to receive_messages(pipeline_bridges: bridges_paginator, pipeline_jobs: jobs_paginator)
      end

      it 'returns early without downloading' do
        expect(client).not_to receive(:download_job_artifact_file)

        downloader.run
      end
    end
  end

  describe '#child_pipeline_id (private)' do
    subject(:downloader) { described_class.new }

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when e2e:test-on-gdk bridge exists with downstream pipeline' do
      let(:bridge) { double(name: 'e2e:test-on-gdk', downstream_pipeline: double(id: 11111)) }
      let(:bridges_paginator) { double(auto_paginate: [bridge]) }

      before do
        allow(client).to receive(:pipeline_bridges).and_return(bridges_paginator)
      end

      it 'returns the child pipeline ID' do
        result = downloader.send(:child_pipeline_id)

        expect(result).to eq(11111)
      end
    end

    context 'when e2e:test-on-gdk bridge is not found' do
      let(:bridges_paginator) { double(auto_paginate: []) }

      before do
        allow(client).to receive(:pipeline_bridges).and_return(bridges_paginator)
      end

      it 'returns nil' do
        result = downloader.send(:child_pipeline_id)

        expect(result).to be_nil
      end
    end

    context 'when bridge exists but has no downstream pipeline' do
      let(:bridge) { double(name: 'e2e:test-on-gdk', downstream_pipeline: nil) }
      let(:bridges_paginator) { double(auto_paginate: [bridge]) }

      before do
        allow(client).to receive(:pipeline_bridges).and_return(bridges_paginator)
      end

      it 'returns nil' do
        result = downloader.send(:child_pipeline_id)

        expect(result).to be_nil
      end
    end
  end

  describe '#find_job_id (private)' do
    subject(:downloader) { described_class.new }

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when process-backend-coverage job exists' do
      let(:job) { double(name: 'process-backend-coverage', id: 22222) }
      let(:jobs_paginator) { double(auto_paginate: [job]) }

      before do
        allow(client).to receive(:pipeline_jobs).and_return(jobs_paginator)
      end

      it 'returns the job ID' do
        result = downloader.send(:find_job_id, 11111, 'process-backend-coverage')

        expect(result).to eq(22222)
      end
    end

    context 'when job is not found' do
      let(:jobs_paginator) { double(auto_paginate: []) }

      before do
        allow(client).to receive(:pipeline_jobs).and_return(jobs_paginator)
      end

      it 'returns nil' do
        result = downloader.send(:find_job_id, 11111, 'process-backend-coverage')

        expect(result).to be_nil
      end
    end
  end

  describe '#download_artifacts (private)' do
    subject(:downloader) { described_class.new }

    let(:job_id) { 22222 }

    before do
      allow(downloader).to receive(:puts)
    end

    context 'when download and extraction succeed' do
      before do
        allow(client).to receive(:download_job_artifact_file).and_return('artifact data')
        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(true)
      end

      it 'downloads and extracts artifacts' do
        expect(client).to receive(:download_job_artifact_file).with(project_id, job_id)

        downloader.send(:download_artifacts, job_id)
      end
    end

    context 'when extraction fails' do
      before do
        allow(client).to receive(:download_job_artifact_file).and_return('artifact data')
        allow(downloader).to receive(:system).with('unzip', '-o', anything).and_return(false)
      end

      it 'exits with error' do
        expect { downloader.send(:download_artifacts, job_id) }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles
