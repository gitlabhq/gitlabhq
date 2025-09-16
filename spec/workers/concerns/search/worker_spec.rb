# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Worker, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'Search::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
      include ::Search::Worker

      pause_control :advanced_search

      def perform
        logger.info 'Worker start'
      end
    end
  end

  let(:worker) { worker_class.new }

  it 'sets the feature category to :global_search' do
    expect(worker_class.get_feature_category).to eq(:global_search)
  end

  it 'sets the concurrency limit to default_concurrency_limit' do
    limit = 55
    expect(Search).to receive(:default_concurrency_limit).and_return(limit)

    expect(worker_class.get_concurrency_limit).to eq(limit)
  end

  it 'uses a logger built with Gitlab::Elasticsearch::Logger' do
    logger = instance_double(Gitlab::Elasticsearch::Logger)
    expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger)
    expect(logger).to receive(:info).with('Worker start')

    worker.perform
  end

  context 'when EE edition', if: Gitlab.ee? do
    # before adding new exceptions, make sure one of the following is true for the worker
    #  - check elasticsearch_pause_indexing
    #  - no direct calls to index or update data,
    #  - no sync indexing requests
    #  - only queues indexing through calls to track! (for advanced search) or schedules other workers
    let(:exceptions) do
      [
        # checks elasticsearch_pause_indexing
        ElasticIndexInitialBulkCronWorker,
        ElasticIndexBulkCronWorker,
        Search::ElasticIndexEmbeddingBulkCronWorker,
        # advanced search framework operations
        Elastic::MigrationWorker,
        ElasticClusterReindexingCronWorker,
        Search::Elastic::TriggerIndexingWorker,
        Search::Elastic::MetricsUpdateCronWorker,
        Elastic::ProjectTransferWorker,
        Elastic::NamespaceUpdateWorker,
        Search::ElasticDefaultBranchChangedWorker,
        Search::ProjectIndexIntegrityWorker,
        Search::NamespaceIndexIntegrityWorker,
        # zoekt framework operations
        Search::Zoekt::IndexingTaskWorker,
        Search::Zoekt::MetricsUpdateCronWorker,
        Search::Zoekt::RolloutWorker,
        Search::Zoekt::SchedulingWorker,
        Search::Zoekt::DefaultBranchChangedWorker,
        # deprecated
        ElasticNamespaceRolloutWorker
      ]
    end

    it 'all workers use pause_control', :eager_load, :aggregate_failures do
      workers = ObjectSpace.each_object(::Class).select do |klass|
        klass.included_modules.include?(::Search::Worker) && exceptions.exclude?(klass)
      end

      expect(workers).not_to be_empty

      workers.each do |worker|
        expect(worker.get_pause_control).not_to be_nil, "#{worker.name} should have pause_control set"
      end
    end
  end
end
