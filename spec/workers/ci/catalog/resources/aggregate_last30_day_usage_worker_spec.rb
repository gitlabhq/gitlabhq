# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::AggregateLast30DayUsageWorker, feature_category: :pipeline_composition do
  let_it_be(:service_response) { ServiceResponse.success(message: 'Usage counts updated for components and resources') }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has the option to reschedule once if deduplicated and a TTL' do
    expect(described_class.get_deduplication_options).to include(
      { if_deduplicated: :reschedule_once, ttl: Gitlab::Ci::Components::Usages::Aggregator::WORKER_DEDUP_TTL })
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    it 'calls the aggregation service' do
      service = instance_double(Ci::Catalog::Resources::AggregateLast30DayUsageService, execute: service_response)
      expect(Ci::Catalog::Resources::AggregateLast30DayUsageService).to receive(:new).and_return(service)

      perform
    end

    it 'logs the service response' do
      allow_next_instance_of(Ci::Catalog::Resources::AggregateLast30DayUsageService) do |service|
        allow(service).to receive(:execute).and_return(service_response)
      end

      expect_next_instance_of(described_class) do |worker|
        expect(worker).to receive(:log_hash_metadata_on_done)
          .with(
            status: :success,
            message: 'Usage counts updated for components and resources'
          )
      end

      perform
    end

    context 'when service fails' do
      let(:error_response) { ServiceResponse.error(message: 'Something went wrong') }

      it 'logs the error response' do
        allow_next_instance_of(Ci::Catalog::Resources::AggregateLast30DayUsageService) do |service|
          allow(service).to receive(:execute).and_return(error_response)
        end

        expect_next_instance_of(described_class) do |worker|
          expect(worker).to receive(:log_hash_metadata_on_done)
            .with(
              status: :error,
              message: 'Something went wrong'
            )
        end

        perform
      end
    end
  end

  it_behaves_like 'an idempotent worker'
end
