require 'spec_helper'

describe 'Every Sidekiq worker' do
  it 'includes ApplicationWorker' do
    expect(Gitlab::SidekiqConfig.workers).to all(include(ApplicationWorker))
  end

  it 'does not use the default queue' do
    expect(Gitlab::SidekiqConfig.workers.map(&:queue)).not_to include('default')
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    expect(Gitlab::SidekiqConfig.cron_workers.map(&:queue)).to all(eq('cronjob'))
  end

  it 'defines the queue in the Sidekiq configuration file' do
    config_queue_names = Gitlab::SidekiqConfig.config_queues.to_set

    expect(Gitlab::SidekiqConfig.worker_queues).to all(be_in(config_queue_names))
  end
end
