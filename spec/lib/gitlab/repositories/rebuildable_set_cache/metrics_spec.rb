# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::RebuildableSetCache::Metrics, :prometheus,
  feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  subject(:metrics) { described_class.new }

  describe '#increment_operation' do
    where(:key, :ref_type, :operation, :status) do
      :branch_names | 'branch'  | 'fetch'   | 'hit'
      'tag_names'   | 'tag'     | 'rebuild' | 'success'
      :other        | 'unknown' | 'update'  | 'error'
    end

    with_them do
      it 'increments the selected operation series' do
        selected_labels = { operation: operation, ref_type: ref_type, status: status }

        expect do
          metrics.increment_operation(key: key, operation: operation, status: status)
        end.to change { operation_metric_value(selected_labels) }.by(1)
      end
    end

    it 'does not report unknown cache keys as errors' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

      metrics.increment_operation(key: :unknown, operation: 'fetch', status: 'hit')
    end
  end

  describe '#increment_trust_event' do
    where(:key, :ref_type, :event) do
      :branch_names | 'branch'  | 'granted'
      'tag_names'   | 'tag'     | 'revoked'
      :other        | 'unknown' | 'grant_skipped'
    end

    with_them do
      it 'increments the selected trust event series' do
        selected_labels = { ref_type: ref_type, event: event }

        expect do
          metrics.increment_trust_event(key: key, event: event)
        end.to change { trust_event_metric_value(selected_labels) }.by(1)
      end
    end
  end

  describe 'metric failures' do
    let(:error) { StandardError.new('failure') }

    it 'tracks registration failures without propagating them to the caller' do
      allow(Gitlab::Metrics).to receive(:counter).and_raise(error)

      expect(Gitlab::ErrorTracking).to receive(:track_exception)
        .with(error, key: :branch_names, operation: 'fetch')

      metrics.increment_operation(key: :branch_names, operation: 'fetch', status: 'hit')
    end

    it 'tracks increment failures without propagating them to the caller' do
      counter = instance_double(Prometheus::Client::Counter)
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
      allow(counter).to receive(:increment).and_raise(error)

      expect(Gitlab::ErrorTracking).to receive(:track_exception)
        .with(error, key: :branch_names, operation: 'fetch')

      metrics.increment_operation(key: :branch_names, operation: 'fetch', status: 'hit')
    end

    it 'swallows increment and error reporting failures' do
      counter = instance_double(Prometheus::Client::Counter, increment: nil)
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
      allow(counter).to receive(:increment).and_raise(StandardError, 'metrics failure')
      allow(Gitlab::ErrorTracking).to receive(:track_exception).and_raise(StandardError, 'reporting failure')

      expect do
        metrics.increment_operation(key: :branch_names, operation: 'fetch', status: 'hit')
        metrics.increment_trust_event(key: :branch_names, event: 'revoked')
      end.not_to raise_error
    end
  end

  def operation_metric
    Gitlab::Metrics.client.get(:gitlab_ref_cache_operations_total)
  end

  def trust_event_metric
    Gitlab::Metrics.client.get(:gitlab_ref_cache_trust_events_total)
  end

  def operation_metric_value(labels)
    operation_metric&.get(labels).to_f
  end

  def trust_event_metric_value(labels)
    trust_event_metric&.get(labels).to_f
  end
end
