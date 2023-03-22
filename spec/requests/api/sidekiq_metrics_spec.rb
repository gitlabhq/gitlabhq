# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SidekiqMetrics, feature_category: :shared do
  let(:admin) { create(:user, :admin) }

  describe 'GET sidekiq/*' do
    it 'defines the `queue_metrics` endpoint', :aggregate_failures do
      get api('/sidekiq/queue_metrics', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to match a_hash_including(
        'queues' => a_hash_including(
          'default' => {
            'backlog' => be_a(Integer),
            'latency' => be_a(Integer)
          },
          'mailers' => {
            'backlog' => be_a(Integer),
            'latency' => be_a(Integer)
          }
        )
      )
    end

    it 'defines the `process_metrics` endpoint', :aggregate_failures do
      get api('/sidekiq/process_metrics', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['processes']).to be_an Array
    end

    it 'defines the `job_stats` endpoint', :aggregate_failures do
      get api('/sidekiq/job_stats', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a Hash
      expect(json_response['jobs']).to be_a Hash
      expect(json_response['jobs'].keys)
        .to contain_exactly(*%w[processed failed enqueued dead])
      expect(json_response['jobs'].values).to all(be_an(Integer))
    end

    it 'defines the `compound_metrics` endpoint', :aggregate_failures do
      get api('/sidekiq/compound_metrics', admin, admin_mode: true)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_a Hash
      expect(json_response['queues']).to be_a Hash
      expect(json_response['processes']).to be_an Array
      expect(json_response['jobs']).to be_a Hash
    end
  end
end
