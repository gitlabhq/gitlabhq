# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every Sidekiq worker' do
  let(:workers_without_defaults) do
    Gitlab::SidekiqConfig.workers - Gitlab::SidekiqConfig::DEFAULT_WORKERS
  end

  it 'does not use the default queue' do
    expect(workers_without_defaults.map(&:queue)).not_to include('default')
  end

  it 'uses the cronjob queue when the worker runs as a cronjob' do
    expect(Gitlab::SidekiqConfig.cron_workers.map(&:queue)).to all(start_with('cronjob:'))
  end

  it 'has its queue in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS', :aggregate_failures do
    file_worker_queues = Gitlab::SidekiqConfig.worker_queues.to_set

    worker_queues = Gitlab::SidekiqConfig.workers.map(&:queue).to_set
    worker_queues << ActionMailer::MailDeliveryJob.new.queue_name
    worker_queues << 'default'

    missing_from_file = worker_queues - file_worker_queues
    expect(missing_from_file).to be_empty, "expected #{missing_from_file.to_a.inspect} to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"

    unnecessarily_in_file = file_worker_queues - worker_queues
    expect(unnecessarily_in_file).to be_empty, "expected #{unnecessarily_in_file.to_a.inspect} not to be in Gitlab::SidekiqConfig::QUEUE_CONFIG_PATHS"
  end

  it 'has its queue or namespace in config/sidekiq_queues.yml', :aggregate_failures do
    config_queues = Gitlab::SidekiqConfig.config_queues.to_set

    Gitlab::SidekiqConfig.workers.each do |worker|
      queue = worker.queue
      queue_namespace = queue.split(':').first

      expect(config_queues).to include(queue).or(include(queue_namespace))
    end
  end

  it 'has a value for loggable_arguments' do
    workers_without_defaults.each do |worker|
      expect(worker.klass.loggable_arguments).to be_an(Array)
    end
  end

  describe "feature category declarations" do
    let(:feature_categories) do
      YAML.load_file(Rails.root.join('config', 'feature_categories.yml')).map(&:to_sym).to_set
    end

    # All Sidekiq worker classes should declare a valid `feature_category`
    # or explicitly be excluded with the `feature_category_not_owned!` annotation.
    # Please see doc/development/sidekiq_style_guide.md#feature-categorization for more details.
    it 'has a feature_category or feature_category_not_owned! attribute', :aggregate_failures do
      workers_without_defaults.each do |worker|
        expect(worker.get_feature_category).to be_a(Symbol), "expected #{worker.inspect} to declare a feature_category or feature_category_not_owned!"
      end
    end

    # All Sidekiq worker classes should declare a valid `feature_category`.
    # The category should match a value in `config/feature_categories.yml`.
    # Please see doc/development/sidekiq_style_guide.md#feature-categorization for more details.
    it 'has a feature_category that maps to a value in feature_categories.yml', :aggregate_failures do
      workers_with_feature_categories = workers_without_defaults
                  .select(&:get_feature_category)
                  .reject(&:feature_category_not_owned?)

      workers_with_feature_categories.each do |worker|
        expect(feature_categories).to include(worker.get_feature_category), "expected #{worker.inspect} to declare a valid feature_category, but got #{worker.get_feature_category}"
      end
    end

    # Memory-bound workers are very expensive to run, since they need to run on nodes with very low
    # concurrency, so that each job can consume a large amounts of memory. For this reason, on
    # GitLab.com, when a large number of memory-bound jobs arrive at once, we let them queue up
    # rather than scaling the hardware to meet the SLO. For this reason, memory-bound,
    # high urgency jobs are explicitly discouraged and disabled.
    it 'is (exclusively) memory-bound or high urgency, not both', :aggregate_failures do
      high_urgency_workers = workers_without_defaults
                               .select { |worker| worker.get_urgency == :high }

      high_urgency_workers.each do |worker|
        expect(worker.get_worker_resource_boundary).not_to eq(:memory), "#{worker.inspect} cannot be both memory-bound and high urgency"
      end
    end

    # In high traffic installations, such as GitLab.com, `urgency :high` workers run in a
    # dedicated fleet. In order to ensure short queue times, `urgency :high` jobs have strict
    # SLOs in order to ensure throughput. However, when a worker depends on an external service,
    # such as a user's k8s cluster or a third-party internet service, we cannot guarantee latency,
    # and therefore throughput. An outage to an 3rd party service could therefore impact throughput
    # on other high urgency jobs, leading to degradation through the GitLab application.
    # Please see doc/development/sidekiq_style_guide.md#jobs-with-external-dependencies for more
    # details.
    it 'has (exclusively) external dependencies or is high urgency, not both', :aggregate_failures do
      high_urgency_workers = workers_without_defaults
                               .select { |worker| worker.get_urgency == :high }

      high_urgency_workers.each do |worker|
        expect(worker.worker_has_external_dependencies?).to be_falsey, "#{worker.inspect} cannot have both external dependencies and be high urgency"
      end
    end
  end
end
