# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::SidekiqMetrics, :clean_gitlab_redis_queues, :aggregate_failures, feature_category: :shared do
  let(:instance_count) { 1 }
  let(:admin) { create(:user, :admin) }

  describe 'GET sidekiq/*' do
    %w[/sidekiq/queue_metrics /sidekiq/process_metrics /sidekiq/job_stats
      /sidekiq/compound_metrics].each do |path|
      it_behaves_like 'GET request permissions for admin mode' do
        let(:path) { path }
      end
    end

    shared_examples 'GET sidekiq metrics' do
      before do
        # ProcessSet looks up running processes in Redis.
        # To ensure test coverage, stub some data so it actually performs some iteration.
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq.redis do |r|
            r.sadd('processes', 'teststub')
            r.hset('teststub',
              ['info', Sidekiq.dump_json({ started_at: Time.now.to_i }), "busy", 1, "quiet", 1, "rss", 1, "rtt_us", 1]
            )
          end
        end
      end

      it 'defines the `queue_metrics` endpoint' do
        expect(Gitlab::SidekiqConfig).to receive(:routing_queues).exactly(instance_count).times.and_call_original
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

      it 'defines the `process_metrics` endpoint' do
        expect(Sidekiq::ProcessSet).to receive(:new).exactly(instance_count).times.and_call_original
        get api('/sidekiq/process_metrics', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['processes']).to be_an Array
      end

      it 'defines the `job_stats` endpoint' do
        expect(Sidekiq::Stats).to receive(:new).exactly(instance_count).times.and_call_original
        get api('/sidekiq/job_stats', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a Hash
        expect(json_response['jobs']).to be_a Hash
        expect(json_response['jobs'].keys)
          .to contain_exactly(*%w[processed failed enqueued dead])
        expect(json_response['jobs'].values).to all(be_an(Integer))
      end

      it 'defines the `compound_metrics` endpoint' do
        expect(Sidekiq::Stats).to receive(:new).exactly(instance_count).times.and_call_original
        expect(Sidekiq::ProcessSet).to receive(:new).exactly(instance_count).times.and_call_original
        expect(Gitlab::SidekiqConfig).to receive(:routing_queues).exactly(instance_count).times.and_call_original
        get api('/sidekiq/compound_metrics', admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a Hash
        expect(json_response['queues']).to be_a Hash
        expect(json_response['processes']).to be_an Array
        expect(json_response['jobs']).to be_a Hash
      end
    end

    context 'with multiple Sidekiq Redis' do
      let(:instance_count) { 2 }

      before do
        allow(Gitlab::Redis::Queues)
          .to receive(:instances).and_return({ 'main' => Gitlab::Redis::Queues, 'shard' => Gitlab::Redis::Queues })
      end

      it_behaves_like 'GET sidekiq metrics'
    end

    it_behaves_like 'GET sidekiq metrics'
  end
end
