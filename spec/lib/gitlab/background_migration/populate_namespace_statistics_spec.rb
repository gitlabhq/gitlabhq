# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::PopulateNamespaceStatistics do
  let!(:namespaces) { table(:namespaces) }
  let!(:namespace_statistics) { table(:namespace_statistics) }
  let!(:dependency_proxy_manifests) { table(:dependency_proxy_manifests) }
  let!(:dependency_proxy_blobs) { table(:dependency_proxy_blobs) }

  let!(:group1) { namespaces.create!(id: 10, type: 'Group', name: 'group1', path: 'group1') }
  let!(:group2) { namespaces.create!(id: 20, type: 'Group', name: 'group2', path: 'group2') }

  let!(:group1_manifest) do
    dependency_proxy_manifests.create!(group_id: 10, size: 20, file_name: 'test-file', file: 'test', digest: 'abc123')
  end

  let!(:group2_manifest) do
    dependency_proxy_manifests.create!(group_id: 20, size: 20, file_name: 'test-file', file: 'test', digest: 'abc123')
  end

  let!(:group1_stats) { namespace_statistics.create!(id: 10, namespace_id: 10) }

  let(:ids) { namespaces.pluck(:id) }
  let(:statistics) { [] }

  subject(:perform) { described_class.new.perform(ids, statistics) }

  it 'creates/updates all namespace_statistics and updates root storage statistics', :aggregate_failures do
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group1.id)
    expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group2.id)

    expect { perform }.to change(namespace_statistics, :count).from(1).to(2)

    namespace_statistics.all.each do |stat|
      expect(stat.dependency_proxy_size).to eq 20
      expect(stat.storage_size).to eq 20
    end
  end

  context 'when just a stat is passed' do
    let(:statistics) { [:dependency_proxy_size] }

    it 'calls the statistics update service with just that stat' do
      expect(Groups::UpdateStatisticsService)
        .to receive(:new)
        .with(anything, statistics: [:dependency_proxy_size])
        .twice.and_call_original

      perform
    end
  end

  context 'when a statistics update fails' do
    before do
      error_response = instance_double(ServiceResponse, message: 'an error', error?: true)

      allow_next_instance_of(Groups::UpdateStatisticsService) do |instance|
        allow(instance).to receive(:execute).and_return(error_response)
      end
    end

    it 'logs an error' do
      expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
        expect(instance).to receive(:error).twice
      end

      perform
    end
  end
end
