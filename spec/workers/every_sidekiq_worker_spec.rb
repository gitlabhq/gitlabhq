require 'spec_helper'

describe 'Every Sidekiq worker' do
  let(:workers) do
    root = Rails.root.join('app', 'workers')
    concerns = root.join('concerns').to_s

    workers = Dir[root.join('**', '*.rb')].
      reject { |path| path.start_with?(concerns) }

    workers.map do |path|
      ns = Pathname.new(path).relative_path_from(root).to_s.gsub('.rb', '')

      ns.camelize.constantize
    end
  end

  it 'does not use the default queue' do
    workers.each do |worker|
      expect(worker.sidekiq_options['queue'].to_s).not_to eq('default')
    end
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    cron_workers = Settings.cron_jobs.
      map { |job_name, options| options['job_class'].constantize }.
      to_set

    workers.each do |worker|
      next unless cron_workers.include?(worker)

      expect(worker.sidekiq_options['queue'].to_s).to eq('cronjob')
    end
  end

  it 'defines the queue in the Sidekiq configuration file' do
    config = YAML.load_file(Rails.root.join('config', 'sidekiq_queues.yml').to_s)
    queue_names = config[:queues].map { |(queue, _)| queue }.to_set

    workers.each do |worker|
      expect(queue_names).to include(worker.sidekiq_options['queue'].to_s)
    end
  end
end
