# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StatePropagationService, feature_category: :groups_and_projects do
  let_it_be_with_reload(:root_group) { create(:group) }
  let_it_be_with_reload(:subgroup) { create(:group, parent: root_group) }
  let_it_be_with_reload(:leaf_group) { create(:group, parent: subgroup) }

  subject(:service) { described_class.new(root_group.id, 'archived') }

  shared_examples 'does not log propagation start or completion' do
    it 'does not log propagation start or completion' do
      allow(Gitlab::AppLogger).to receive(:info).and_call_original
      expect(Gitlab::AppLogger).not_to receive(:info)
        .with(hash_including(Labkit::Fields::LOG_MESSAGE => a_string_starting_with('Namespace state propagation')))

      service.execute
    end
  end

  describe '#execute' do
    let!(:propagation) do
      create(:namespace_state_propagation, :ancestor_inherited_to_archived, namespace: root_group)
    end

    it 'marks the outbox record as processing before propagating' do
      statuses = []

      allow(Namespace).to receive(:overwrite_state_in_batch).and_wrap_original do |method, *args, **kwargs|
        statuses << propagation.reload.status
        method.call(*args, **kwargs)
      end

      service.execute

      expect(statuses).to eq(['processing'])
    end

    it 'propagates the target state to overwritable descendants', :aggregate_failures do
      service.execute

      expect(subgroup.reload.state).to eq('archived')
      expect(leaf_group.reload.state).to eq('archived')
    end

    it 'refreshes started_at after each propagated batch' do
      stub_const("#{described_class}::STATE_PROPAGATION_ITERATOR_BATCH_SIZE", 1)
      heartbeats = []

      allow(Namespace).to receive(:overwrite_state_in_batch).and_wrap_original do |method, *args, **kwargs|
        heartbeats << propagation.reload.started_at
        travel 1.minute
        method.call(*args, **kwargs)
      end

      service.execute

      expect(heartbeats.size).to be > 1
      expect(heartbeats).to eq(heartbeats.sort.uniq)
    end

    it 'deletes the outbox record on completion' do
      service.execute

      expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(false)
    end

    it 'observes the propagation duration once' do
      expect(Gitlab::NamespaceStatePropagation::Metrics)
        .to receive(:observe_duration).once.with('archived', a_kind_of(Numeric))

      service.execute
    end

    it 'excludes the claim from the observed duration' do
      clock = 0.0
      allow(::Gitlab::Metrics::System).to receive(:monotonic_time) { clock }
      allow(Namespaces::StatePropagation).to receive(:next_pending_for).and_return(propagation)
      allow(propagation).to receive(:claim).and_wrap_original do |method|
        clock += 100
        method.call
      end

      expect(Gitlab::NamespaceStatePropagation::Metrics).to receive(:observe_duration).with('archived', 0.0)

      service.execute
    end

    it 'increments the boundary rewinds counter when a descendant becomes a boundary mid-walk' do
      create(:group, parent: root_group)
      stub_const("#{described_class}::STATE_PROPAGATION_ITERATOR_BATCH_SIZE", 1)

      allow(Namespace).to receive(:overwrite_state_in_batch).and_wrap_original do |method, *args, **kwargs|
        method.call(*args, **kwargs).tap do
          subgroup.update_column(:state, Namespace.states[:deletion_scheduled])
        end
      end

      expect(Gitlab::NamespaceStatePropagation::Metrics).to receive(:increment_boundary_rewinds).once

      service.execute
    end

    it 'increments the batches counter once per batch' do
      stub_const("#{described_class}::STATE_PROPAGATION_ITERATOR_BATCH_SIZE", 1)
      allow(Namespace).to receive(:overwrite_state_in_batch).and_call_original
      allow(Gitlab::NamespaceStatePropagation::Metrics).to receive(:increment_batches)

      service.execute

      expect(Namespace).to have_received(:overwrite_state_in_batch).twice
      expect(Gitlab::NamespaceStatePropagation::Metrics).to have_received(:increment_batches).with('archived').twice
    end

    describe 'logging' do
      before do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
      end

      it 'logs the propagation start' do
        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
          Labkit::Fields::CLASS_NAME => 'Namespaces::StatePropagationService',
          Labkit::Fields::LOG_MESSAGE => 'Namespace state propagation started',
          Labkit::Fields::GL_NAMESPACE_ID => root_group.id,
          'source_state' => 'ancestor_inherited',
          'target_state' => 'archived'
        ))

        service.execute
      end

      it 'logs the propagation completion' do
        root_group.update!(state: :archived)
        stub_const("#{described_class}::STATE_PROPAGATION_ITERATOR_BATCH_SIZE", 1)
        allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100.0)
        allow(Namespace).to receive(:overwrite_state_in_batch).and_wrap_original do |method, *args, **kwargs|
          allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(101.2345678)
          method.call(*args, **kwargs)
        end

        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
          Labkit::Fields::CLASS_NAME => 'Namespaces::StatePropagationService',
          Labkit::Fields::LOG_MESSAGE => 'Namespace state propagation completed',
          Labkit::Fields::GL_NAMESPACE_ID => root_group.id,
          'target_state' => 'archived',
          'batch_count' => 2,
          Labkit::Fields::DURATION_S => 1.234568,
          'descendants_updated' => 2
        ))

        service.execute
      end
    end

    context 'when a descendant is in a non-overwritable state' do
      before do
        leaf_group.update!(state: :deletion_scheduled)
      end

      it 'does not overwrite the higher-precedence descendant', :aggregate_failures do
        service.execute

        expect(subgroup.reload.state).to eq('archived')
        expect(leaf_group.reload.state).to eq('deletion_scheduled')
      end
    end

    context 'when there are no overwritable states' do
      subject(:service) { described_class.new(root_group.id, 'ancestor_inherited') }

      let!(:propagation) do
        create(:namespace_state_propagation, namespace: root_group,
          source_state: :ancestor_inherited, target_state: :ancestor_inherited)
      end

      it 'does not change any descendant state', :aggregate_failures do
        service.execute

        expect(subgroup.reload.state).to eq('ancestor_inherited')
        expect(leaf_group.reload.state).to eq('ancestor_inherited')
      end

      it 'deletes the outbox record' do
        service.execute

        expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(false)
      end

      it 'does not emit propagation metrics', :aggregate_failures do
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:observe_duration)
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:increment_batches)

        service.execute
      end

      it_behaves_like 'does not log propagation start or completion'
    end

    context 'when the outbox record does not exist' do
      subject(:service) { described_class.new(non_existing_record_id, 'archived') }

      it 'does not change any descendant state and does not raise', :aggregate_failures do
        expect { service.execute }.not_to raise_error

        expect(subgroup.reload.state).to eq('ancestor_inherited')
      end

      it 'does not emit propagation metrics', :aggregate_failures do
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:observe_duration)
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:increment_batches)

        service.execute
      end

      it_behaves_like 'does not log propagation start or completion'
    end

    context 'when the outbox record is already processing' do
      let!(:propagation) do
        create(:namespace_state_propagation, :processing, :ancestor_inherited_to_archived,
          namespace: root_group)
      end

      it 'leaves descendants and the record untouched', :aggregate_failures do
        service.execute

        expect(subgroup.reload.state).to eq('ancestor_inherited')
        expect(propagation.reload).to be_status_processing
      end
    end

    context 'when another job claims the record first' do
      before do
        stale_propagation = Namespaces::StatePropagation.find(propagation.id)
        propagation.claim

        allow(Namespaces::StatePropagation).to receive(:next_pending_for).and_return(stale_propagation)
      end

      it 'leaves descendants untouched' do
        service.execute

        expect(subgroup.reload.state).to eq('ancestor_inherited')
      end

      it 'does not emit propagation metrics', :aggregate_failures do
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:observe_duration)
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:increment_batches)

        service.execute
      end

      it_behaves_like 'does not log propagation start or completion'
    end

    context 'when propagation fails partway through' do
      before do
        stub_const("#{described_class}::STATE_PROPAGATION_ITERATOR_BATCH_SIZE", 1)
        calls = 0

        allow(Namespace).to receive(:overwrite_state_in_batch).and_wrap_original do |method, *args, **kwargs|
          calls += 1
          raise ActiveRecord::StatementInvalid, 'statement failed' if calls > 1

          method.call(*args, **kwargs)
        end
      end

      it 'leaves the outbox record in place as processing for CRON recovery', :aggregate_failures do
        expect { service.execute }.to raise_error(ActiveRecord::StatementInvalid)

        expect(Namespaces::StatePropagation.exists?(propagation.id)).to be(true)
        expect(propagation.reload).to be_status_processing
      end

      it 'does not observe the propagation duration' do
        expect(Gitlab::NamespaceStatePropagation::Metrics).not_to receive(:observe_duration)

        expect { service.execute }.to raise_error(ActiveRecord::StatementInvalid)
      end

      it 'logs the failure and re-raises without logging completion', :aggregate_failures do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
        expect(Gitlab::AppLogger).to receive(:error).with(hash_including(
          Labkit::Fields::CLASS_NAME => 'Namespaces::StatePropagationService',
          Labkit::Fields::LOG_MESSAGE => 'Namespace state propagation failed',
          Labkit::Fields::GL_NAMESPACE_ID => root_group.id,
          'target_state' => 'archived',
          Labkit::Fields::ERROR_TYPE => 'ActiveRecord::StatementInvalid',
          Labkit::Fields::ERROR_MESSAGE => 'statement failed'
        ))
        expect(Gitlab::AppLogger).not_to receive(:info)
          .with(hash_including(Labkit::Fields::LOG_MESSAGE => 'Namespace state propagation completed'))

        expect { service.execute }.to raise_error(ActiveRecord::StatementInvalid)

        expect(propagation.reload).to be_status_processing
      end
    end
  end
end
