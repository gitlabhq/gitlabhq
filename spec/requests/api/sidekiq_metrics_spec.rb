# frozen_string_literal: true

require 'spec_helper'

describe API::SidekiqMetrics do
  let(:admin) { create(:user, :admin) }

  describe 'GET sidekiq/*' do
    it 'defines the `queue_metrics` endpoint' do
      get api('/sidekiq/queue_metrics', admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_a Hash
    end

    it 'defines the `process_metrics` endpoint' do
      get api('/sidekiq/process_metrics', admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response['processes']).to be_an Array
    end

    it 'defines the `job_stats` endpoint' do
      get api('/sidekiq/job_stats', admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_a Hash
      expect(json_response['jobs']).to be_a Hash
      expect(json_response['jobs'].keys)
        .to contain_exactly(*%w[processed failed enqueued dead])
      expect(json_response['jobs'].values).to all(be_an(Integer))
    end

    it 'defines the `compound_metrics` endpoint' do
      get api('/sidekiq/compound_metrics', admin)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to be_a Hash
      expect(json_response['queues']).to be_a Hash
      expect(json_response['processes']).to be_an Array
      expect(json_response['jobs']).to be_a Hash
    end
  end
end
