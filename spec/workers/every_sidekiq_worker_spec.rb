require 'spec_helper'

describe 'Every Sidekiq worker' do
  it 'does not use the default queue' do
    expect(Gitlab::SidekiqConfig.workers.map(&:queue)).not_to include('default')
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    expect(Gitlab::SidekiqConfig.cron_workers.map(&:queue)).to all(start_with('cronjob:'))
  end

  it 'has its queue in app/workers/all_queues.yml', :aggregate_failures do
    file_worker_queues = Gitlab::SidekiqConfig.worker_queues.to_set

    worker_queues = Gitlab::SidekiqConfig.workers.map(&:queue).to_set
    worker_queues << ActionMailer::DeliveryJob.queue_name
    worker_queues << 'default'

    missing_from_file = worker_queues - file_worker_queues
    expect(missing_from_file).to be_empty, "expected #{missing_from_file.to_a.inspect} to be in app/workers/all_queues.yml"

    unncessarily_in_file = file_worker_queues - worker_queues
    expect(unncessarily_in_file).to be_empty, "expected #{unncessarily_in_file.to_a.inspect} not to be in app/workers/all_queues.yml"
  end

  it 'has its queue or namespace in config/sidekiq_queues.yml', :aggregate_failures do
    config_queues = Gitlab::SidekiqConfig.config_queues.to_set

    Gitlab::SidekiqConfig.workers.each do |worker|
      queue = worker.queue
      queue_namespace = queue.split(':').first

      expect(config_queues).to include(queue).or(include(queue_namespace))
    end
  end
end
