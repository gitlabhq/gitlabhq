# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::NamespaceStatePropagation::Metrics, feature_category: :groups_and_projects do
  let(:histogram) { instance_double(Prometheus::Client::Histogram, observe: nil) }
  let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }

  describe '.observe_duration' do
    it 'observes the duration labelled by target state' do
      expect(Gitlab::Metrics).to receive(:histogram).with(
        :gitlab_namespaces_state_propagation_duration_seconds,
        anything,
        {},
        described_class::DURATION_BUCKETS
      ).and_return(histogram)
      expect(histogram).to receive(:observe).with({ target_state: 'archived' }, 1.5)

      described_class.observe_duration(:archived, 1.5)
    end
  end

  describe '.increment_batches' do
    it 'increments the batches counter labelled by target state' do
      expect(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_namespaces_state_propagation_batches_total, anything).and_return(counter)
      expect(counter).to receive(:increment).with(target_state: 'archived')

      described_class.increment_batches(:archived)
    end
  end

  describe '.increment_boundary_rewinds' do
    it 'increments the boundary rewinds counter' do
      expect(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_namespaces_state_propagation_boundary_rewinds_total, anything).and_return(counter)
      expect(counter).to receive(:increment).with(no_args)

      described_class.increment_boundary_rewinds
    end
  end

  describe '.increment_failures' do
    it 'increments the failures counter labelled by target state' do
      expect(Gitlab::Metrics).to receive(:counter)
        .with(:gitlab_namespaces_state_propagation_failures_total, anything).and_return(counter)
      expect(counter).to receive(:increment).with(target_state: 'deletion_scheduled')

      described_class.increment_failures('deletion_scheduled')
    end
  end

  describe '.update_outbox_gauges' do
    let_it_be(:group) { create(:group) }
    let_it_be(:other_group) { create(:group) }
    let_it_be(:third_group) { create(:group) }

    let_it_be(:processing_propagation) { create(:namespace_state_propagation, :processing, namespace: third_group) }

    let(:pending_gauge) { instance_double(Prometheus::Client::Gauge, set: nil) }
    let(:processing_gauge) { instance_double(Prometheus::Client::Gauge, set: nil) }

    before_all do
      create(:namespace_state_propagation, namespace: group)
      create(:namespace_state_propagation, namespace: other_group)
    end

    before do
      allow(Gitlab::Metrics).to receive(:gauge)
        .with(:gitlab_namespaces_state_propagation_pending_records, anything, {}, :max)
        .and_return(pending_gauge)
      allow(Gitlab::Metrics).to receive(:gauge)
        .with(:gitlab_namespaces_state_propagation_processing_records, anything, {}, :max)
        .and_return(processing_gauge)
    end

    it 'sets the gauges from the outbox record counts', :aggregate_failures do
      expect(pending_gauge).to receive(:set).with({}, 2)
      expect(processing_gauge).to receive(:set).with({}, 1)

      described_class.update_outbox_gauges
    end

    context 'when a status has no outbox records' do
      before do
        processing_propagation.destroy!
      end

      it 'sets its gauge to zero', :aggregate_failures do
        expect(pending_gauge).to receive(:set).with({}, 2)
        expect(processing_gauge).to receive(:set).with({}, 0)

        described_class.update_outbox_gauges
      end
    end
  end
end
