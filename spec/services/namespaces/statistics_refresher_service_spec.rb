# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StatisticsRefresherService, '#execute' do
  let(:group) { create(:group) }
  let(:projects) { create_list(:project, 5, namespace: group) }
  let(:service) { described_class.new }

  context 'without a root storage statistics relation' do
    it 'creates one' do
      expect do
        service.execute(group)
      end.to change(Namespace::RootStorageStatistics, :count).by(1)

      expect(group.reload.root_storage_statistics).to be_present
    end

    it 'recalculate the namespace statistics' do
      expect_next_instance_of(Namespace::RootStorageStatistics) do |instance|
        expect(instance).to receive(:recalculate!).once
      end

      service.execute(group)
    end
  end

  context 'with a root storage statistics relation', :sidekiq_might_not_need_inline do
    before do
      Namespace::AggregationSchedule.safe_find_or_create_by!(namespace_id: group.id)
    end

    it 'does not create one' do
      expect do
        service.execute(group)
      end.not_to change(Namespace::RootStorageStatistics, :count)
    end

    it 'recalculate the namespace statistics' do
      expect(Namespace::RootStorageStatistics)
        .to receive(:safe_find_or_create_by!).with({ namespace_id: group.id })
        .and_return(group.root_storage_statistics)

      service.execute(group)
    end
  end

  context 'when something goes wrong' do
    before do
      allow_next_instance_of(Namespace::RootStorageStatistics) do |instance|
        allow(instance).to receive(:recalculate!).and_raise(ActiveRecord::ActiveRecordError)
      end
    end

    it 'raises RefreshError' do
      expect do
        service.execute(group)
      end.to raise_error(Namespaces::StatisticsRefresherService::RefresherError)
    end
  end
end
