# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceStatistics, type: :model, feature_category: :consumables_cost_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  it { is_expected.to belong_to(:namespace) }

  it { is_expected.to validate_presence_of(:namespace) }

  describe '#refresh!' do
    let(:namespace) { group }
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:columns) { [] }

    subject(:refresh!) { statistics.refresh!(only: columns) }

    context 'when database is read_only' do
      it 'does not save the object' do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)

        expect(statistics).not_to receive(:save!)

        refresh!
      end
    end

    context 'when namespace belong to a user' do
      let(:namespace) { user.namespace }

      it 'does not save the object' do
        expect(statistics).not_to receive(:save!)

        refresh!
      end
    end

    shared_examples 'creates the namespace statistics' do
      specify do
        expect(statistics).to receive(:save!)

        refresh!
      end
    end

    context 'when invalid option is passed' do
      let(:columns) { [:foo] }

      it 'does not update any column' do
        create(:dependency_proxy_manifest, group: namespace, size: 50)

        expect(statistics).not_to receive(:update_dependency_proxy_size)
        expect { refresh! }.not_to change { statistics.reload.storage_size }
      end

      it_behaves_like 'creates the namespace statistics'
    end

    context 'when no option is passed' do
      it 'updates the dependency proxy size' do
        expect(statistics).to receive(:update_dependency_proxy_size)

        refresh!
      end

      it_behaves_like 'creates the namespace statistics'
    end

    context 'when dependency_proxy_size option is passed' do
      let(:columns) { [:dependency_proxy_size] }

      it 'updates the dependency proxy size' do
        expect(statistics).to receive(:update_dependency_proxy_size)

        refresh!
      end

      it_behaves_like 'creates the namespace statistics'
    end
  end

  describe '#update_storage_size' do
    let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: group) }

    it 'sets storage_size to the dependency_proxy_size' do
      statistics.dependency_proxy_size = 3

      statistics.update_storage_size

      expect(statistics.storage_size).to eq 3
    end
  end

  describe '#update_dependency_proxy_size' do
    let_it_be(:statistics, reload: true) { create(:namespace_statistics, namespace: group) }
    let_it_be(:dependency_proxy_manifest) { create(:dependency_proxy_manifest, group: group, size: 50) }
    let_it_be(:dependency_proxy_blob) { create(:dependency_proxy_blob, group: group, size: 50) }
    let_it_be(:vreg_maven_cache_entry) { create(:virtual_registries_packages_maven_cache_entry, group: group, size: 50) }

    subject(:update_dependency_proxy_size) { statistics.update_dependency_proxy_size }

    it 'updates the dependency proxy size' do
      update_dependency_proxy_size

      expect(statistics.dependency_proxy_size).to eq 150
    end

    context 'when namespace does not belong to a group' do
      let(:statistics) { create(:namespace_statistics, namespace: user.namespace) }

      it 'does not update the dependency proxy size' do
        update_dependency_proxy_size

        expect(statistics.dependency_proxy_size).to be_zero
      end
    end
  end

  context 'before saving statistics' do
    let(:statistics) { create(:namespace_statistics, namespace: group, dependency_proxy_size: 10) }

    it 'updates storage size' do
      expect(statistics).to receive(:update_storage_size).and_call_original

      statistics.save!

      expect(statistics.storage_size).to eq 10
    end
  end

  context 'after saving statistics', :aggregate_failures do
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:namespace) { group }

    context 'when storage_size is not updated' do
      it 'does not enqueue the job to update root storage statistics' do
        expect(statistics).not_to receive(:update_root_storage_statistics)
        expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

        statistics.save!
      end
    end

    context 'when storage_size is updated' do
      before do
        # we have to update this value instead of `storage_size` because the before_save
        # hook we have. If we don't do it, storage_size will be set to the dependency_proxy_size value
        # which is 0.
        statistics.dependency_proxy_size = 10
      end

      it 'enqueues the job to update root storage statistics' do
        expect(statistics).to receive(:update_root_storage_statistics).and_call_original
        expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group.id)

        statistics.save!
      end

      context 'when namespace does not belong to a group' do
        let(:namespace) { user.namespace }

        it 'does not enqueue the job to update root storage statistics' do
          expect(statistics).to receive(:update_root_storage_statistics).and_call_original
          expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

          statistics.save!
        end
      end
    end

    context 'when other columns are updated' do
      it 'does not enqueue the job to update root storage statistics' do
        columns_to_update = NamespaceStatistics.columns_hash.reject { |k, _| %w[id namespace_id].include?(k) || k.include?('_size') }.keys
        columns_to_update.each { |c| statistics[c] = 10 }

        expect(statistics).not_to receive(:update_root_storage_statistics)
        expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

        statistics.save!
      end
    end
  end

  context 'after destroy statistics', :aggregate_failures do
    let(:statistics) { create(:namespace_statistics, namespace: namespace) }
    let(:namespace) { group }

    it 'enqueues the job to update root storage statistics' do
      expect(statistics).to receive(:update_root_storage_statistics).and_call_original
      expect(Namespaces::ScheduleAggregationWorker).to receive(:perform_async).with(group.id)

      statistics.destroy!
    end

    context 'when namespace belongs to a group' do
      let(:namespace) { user.namespace }

      it 'does not enqueue the job to update root storage statistics' do
        expect(statistics).to receive(:update_root_storage_statistics).and_call_original
        expect(Namespaces::ScheduleAggregationWorker).not_to receive(:perform_async)

        statistics.destroy!
      end
    end
  end
end
