# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles -- generic double is sufficient

require 'fast_spec_helper'

require_relative '../../scripts/check_default_pipeline_status'

RSpec.describe CheckDefaultPipelineStatus, feature_category: :tooling do
  let(:api_client_double)      { double('Client') }
  let(:master_pipeline_status) { 'failed' }
  let(:allowed_to_fail)        { false }
  let(:failed_job_double)      { double('Job', name: 'job_name', allow_failure: allowed_to_fail) }
  let(:pipeline_jobs_double)   { double('pipeline_jobs', auto_paginate: [failed_job_double]) }

  subject(:master_pipeline_status_checker) do
    described_class.new({ project: '1', pipeline_id: '100', api_token: 'api-token', endpoint: '' })
  end

  before do
    allow(Gitlab).to receive(:client).and_return(api_client_double)

    allow(api_client_double).to receive(:pipelines).with(
      '1',
      ref: 'master',
      scope: 'finished',
      per_page: 1
    ).and_return([double('Pipeline', id: '1', web_url: 'master_web_url', status: master_pipeline_status)])

    allow(api_client_double).to receive(:pipeline_jobs).and_return(
      double(
        'master_pipeline_jobs',
        auto_paginate: [
          double('Job', name: 'job1', allow_failure: true),
          failed_job_double
        ]
      ),
      pipeline_jobs_double
    )
  end

  shared_examples 'exits successfully' do
    it 'returns' do
      expect(master_pipeline_status_checker.execute).to be nil
    end
  end

  describe 'execute' do
    context 'when the latest master pipeline succeeded' do
      let(:master_pipeline_status) { 'success' }

      it_behaves_like 'exits successfully'
    end

    context 'when the latest master pipeline failed' do
      context 'when the current pipeline does not contain any failed job from master' do
        let(:pipeline_jobs_double) do
          double('pipeline_jobs', auto_paginate: [double('Job', name: 'new-job', allow_failure: true)])
        end

        it_behaves_like 'exits successfully'
      end

      context 'when the current pipeline contains a failed job from master' do
        context 'when the matching job is allowed to fail' do
          let(:allowed_to_fail) { true }

          it_behaves_like 'exits successfully'
        end

        context 'when the matching job is not allowed to fail' do
          it 'raises system exit error' do
            expect(master_pipeline_status_checker).to receive(:warn).with(
              <<~TEXT
              ******************************************************************************************
              We are failing this job to warn you that you may be impacted by a master broken incident.
              Jobs below may fail in your pipeline:
              job_name
              Check if the failures are also present in the master pipeline: master_web_url
              Reach out to #master-broken for assistance if you think you are blocked.
              Apply ~"pipeline:ignore-master-status" to skip this job if you don't think this is helpful.
              ******************************************************************************************
              TEXT
            )
            expect { master_pipeline_status_checker.execute }.to raise_error(SystemExit)
          end
        end
      end
    end
  end
end

# rubocop:enable RSpec/VerifiedDoubles
