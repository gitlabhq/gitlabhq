# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqConfig do
  before do
    # Remove cache
    described_class.instance_variable_set(:@workers, nil)
  end

  describe '.workers' do
    it 'includes all workers' do
      worker_classes = described_class.workers.map(&:klass)

      expect(worker_classes).to include(PostReceive)
      expect(worker_classes).to include(MergeWorker)
    end
  end

  describe '.cron_jobs' do
    around do |example|
      described_class.clear_memoization(:cron_jobs)

      example.run

      described_class.clear_memoization(:cron_jobs)
    end

    it 'renames job_class to class and removes incomplete jobs' do
      expect(Gitlab)
        .to receive(:config)
        .twice
        .and_return(GitlabSettings::Options.build(
          load_dynamic_cron_schedules!: true,
          cron_jobs: {
            job: { cron: '0 * * * *', job_class: 'SomeWorker' },
            incomplete_job: { cron: '0 * * * *' }
          }))

      expect(Gitlab::AppLogger)
        .to receive(:error)
        .with("Invalid cron_jobs config key: 'incomplete_job'. Check your gitlab config file.")

      expect(described_class.cron_jobs)
        .to eq('job' => { 'class' => 'SomeWorker', 'cron' => '0 * * * *' })
    end
  end

  describe '.worker_queues' do
    it 'includes all queues' do
      queues = described_class.worker_queues

      expect(queues).to include('post_receive')
      expect(queues).to include('merge')
      expect(queues).to include('cronjob:import_stuck_project_import_jobs')
      expect(queues).to include('cronjob:jira_import_stuck_jira_import_jobs')
      expect(queues).to include('mailers')
      expect(queues).to include('default')
    end
  end

  describe '.workers_for_all_queues_yml' do
    it 'returns a tuple with FOSS workers first' do
      expect(described_class.workers_for_all_queues_yml.first)
        .to include(an_object_having_attributes(generated_queue_name: 'post_receive'))
    end
  end

  describe '.all_queues_yml_outdated?' do
    let(:workers) do
      [
        MergeWorker,
        PostReceive,
        ProcessCommitWorker
      ].map { |worker| described_class::Worker.new(worker, ee: false) }
    end

    before do
      allow(described_class).to receive(:workers).and_return(workers)
      allow(Gitlab).to receive(:ee?).and_return(false)
      allow(Gitlab).to receive(:jh?).and_return(false)
    end

    it 'returns true if the YAML file does not match the application code' do
      allow(YAML).to receive(:load_file)
                       .with(described_class::FOSS_QUEUE_CONFIG_PATH)
                       .and_return(workers.first(2).map(&:to_yaml))

      expect(described_class.all_queues_yml_outdated?).to be(true)
    end

    it 'returns false if the YAML file matches the application code' do
      allow(YAML).to receive(:load_file)
                       .with(described_class::FOSS_QUEUE_CONFIG_PATH)
                       .and_return(workers.map(&:to_yaml))

      expect(described_class.all_queues_yml_outdated?).to be(false)
    end
  end

  describe '.queues_for_sidekiq_queues_yml' do
    before do
      workers = [
        Namespaces::RootStatisticsWorker,
        Namespaces::ScheduleAggregationWorker,
        MergeWorker,
        ProcessCommitWorker
      ].map { |worker| described_class::Worker.new(worker, ee: false) }

      allow(described_class).to receive(:workers).and_return(workers)
    end

    it 'returns queues and weights, aggregating namespaces with the same weight' do
      expected_queues = [
        ['merge', 5],
        ['process_commit', 3],
        ['update_namespace_statistics', 1]
      ]

      expect(described_class.queues_for_sidekiq_queues_yml).to eq(expected_queues)
    end
  end

  describe '.sidekiq_queues_yml_outdated?' do
    before do
      workers = [
        Namespaces::RootStatisticsWorker,
        Namespaces::ScheduleAggregationWorker,
        MergeWorker,
        ProcessCommitWorker
      ].map { |worker| described_class::Worker.new(worker, ee: false) }

      allow(described_class).to receive(:workers).and_return(workers)
      allow(Gitlab).to receive(:jh?).and_return(false)
    end

    let(:expected_queues) do
      [
        ['merge', 5],
        ['process_commit', 3],
        ['update_namespace_statistics', 1]
      ]
    end

    it 'returns true if the YAML file does not match the application code' do
      allow(YAML).to receive(:load_file)
                       .with(described_class::SIDEKIQ_QUEUES_PATH)
                       .and_return(queues: expected_queues.reverse)

      expect(described_class.sidekiq_queues_yml_outdated?).to be(true)
    end

    it 'returns false if the YAML file matches the application code' do
      allow(YAML).to receive(:load_file)
                       .with(described_class::SIDEKIQ_QUEUES_PATH)
                       .and_return(queues: expected_queues)

      expect(described_class.sidekiq_queues_yml_outdated?).to be(false)
    end
  end

  describe '.worker_queue_mappings' do
    it 'returns the worker class => queue mappings based on the current routing configuration' do
      test_routes = [
        ['urgency=high', 'default'],
        ['*', nil]
      ]

      allow(::Gitlab::SidekiqConfig::WorkerRouter)
        .to receive(:global).and_return(::Gitlab::SidekiqConfig::WorkerRouter.new(test_routes))

      expect(described_class.worker_queue_mappings).to include('MergeWorker' => 'default',
        'Ci::BuildFinishedWorker' => 'default',
        'AdminEmailWorker' => 'cronjob:admin_email')
    end
  end

  describe '.current_worker_queue_mappings' do
    it 'returns worker queue mappings that have queues in the current Sidekiq options' do
      test_routes = [
        ['urgency=high', 'default'],
        ['*', nil]
      ]

      allow(::Gitlab::SidekiqConfig::WorkerRouter)
        .to receive(:global).and_return(::Gitlab::SidekiqConfig::WorkerRouter.new(test_routes))

      allow(Sidekiq).to receive_message_chain(:default_configuration, :queues)
        .and_return(%w[default])

      mappings = described_class.current_worker_queue_mappings

      expect(mappings).to include('MergeWorker' => 'default', 'Ci::BuildFinishedWorker' => 'default')

      expect(mappings).not_to include('AdminEmailWorker' => 'cronjob:admin_email')
    end
  end

  describe '.routing_queues' do
    let(:test_routes) do
      [
        ['tags=needs_own_queue', nil],
        ['urgency=high', 'high_urgency'],
        ['feature_category=gitaly', 'gitaly'],
        ['feature_category=not_exist', 'not_exist'],
        ['*', 'default']
      ]
    end

    before do
      described_class.instance_variable_set(:@routing_queues, nil)
      allow(::Gitlab::SidekiqConfig::WorkerRouter)
        .to receive(:global).and_return(::Gitlab::SidekiqConfig::WorkerRouter.new(test_routes))
    end

    after do
      described_class.instance_variable_set(:@routing_queues, nil)
    end

    it 'returns worker queue mappings that have queues in the current Sidekiq options' do
      queues = described_class.routing_queues

      expect(queues).to match_array(%w[default mailers high_urgency gitaly])
      expect(queues).not_to include('not_exist')
    end
  end
end
