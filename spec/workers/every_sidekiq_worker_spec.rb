# frozen_string_literal: true

require 'spec_helper'

describe 'Every Sidekiq worker' do
  it 'does not use the default queue' do
    expect(Gitlab::SidekiqConfig.workers.map(&:queue)).not_to include('default')
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    expect(Gitlab::SidekiqConfig.cron_workers.map(&:queue)).to all(start_with('cronjob:'))
  end

  it 'has its queue in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS', :aggregate_failures do
    file_worker_queues = Gitlab::SidekiqConfig.worker_queues.to_set

    worker_queues = Gitlab::SidekiqConfig.workers.map(&:queue).to_set
    worker_queues << ActionMailer::DeliveryJob.new.queue_name
    worker_queues << 'default'

    missing_from_file = worker_queues - file_worker_queues
    expect(missing_from_file).to be_empty, "expected #{missing_from_file.to_a.inspect} to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"

    unncessarily_in_file = file_worker_queues - worker_queues
    expect(unncessarily_in_file).to be_empty, "expected #{unncessarily_in_file.to_a.inspect} not to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"
  end

  it 'has its queue or namespace in config/sidekiq_queues.yml', :aggregate_failures do
    config_queues = Gitlab::SidekiqConfig.config_queues.to_set

    Gitlab::SidekiqConfig.workers.each do |worker|
      queue = worker.queue
      queue_namespace = queue.split(':').first

      expect(config_queues).to include(queue).or(include(queue_namespace))
    end
  end

  describe "feature category declarations" do
    let(:feature_categories) do
      YAML.load_file(Rails.root.join('config', 'feature_categories.yml')).map(&:to_sym).to_set
    end

    # All Sidekiq worker classes should declare a valid `feature_category`
    # or explicitely be excluded with the `feature_category_not_owned!` annotation.
    # Please see doc/development/sidekiq_style_guide.md#Feature-Categorization for more details.
    it 'has a feature_category or feature_category_not_owned! attribute', :aggregate_failures do
      Gitlab::SidekiqConfig.workers.each do |worker|
        expect(worker.get_feature_category).to be_a(Symbol), "expected #{worker.inspect} to declare a feature_category or feature_category_not_owned!"
      end
    end

    # All Sidekiq worker classes should declare a valid `feature_category`.
    # The category should match a value in `config/feature_categories.yml`.
    # Please see doc/development/sidekiq_style_guide.md#Feature-Categorization for more details.
    it 'has a feature_category that maps to a value in feature_categories.yml', :aggregate_failures do
      workers_with_feature_categories = Gitlab::SidekiqConfig.workers
                  .select(&:get_feature_category)
                  .reject(&:feature_category_not_owned?)

      workers_with_feature_categories.each do |worker|
        expect(feature_categories).to include(worker.get_feature_category), "expected #{worker.inspect} to declare a valid feature_category, but got #{worker.get_feature_category}"
      end
    end
  end
end
