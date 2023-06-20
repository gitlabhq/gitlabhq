# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cache::Metrics, feature_category: :source_code_management do
  subject(:metrics) { described_class.new(metadata) }

  let(:metadata) do
    Gitlab::Cache::Metadata.new(
      cache_identifier: cache_identifier,
      feature_category: feature_category,
      backing_resource: backing_resource
    )
  end

  let(:cache_identifier) { 'ApplicationController#show' }
  let(:feature_category) { :source_code_management }
  let(:backing_resource) { :unknown }

  let(:counter_mock) { instance_double(Prometheus::Client::Counter) }

  before do
    allow(Gitlab::Metrics).to receive(:counter)
      .with(
        :redis_hit_miss_operations_total,
        'Hit/miss Redis cache counter',
        {
          cache_identifier: cache_identifier,
          feature_category: feature_category,
          backing_resource: backing_resource
        }
      ).and_return(counter_mock)
  end

  describe '#increment_cache_hit' do
    subject { metrics.increment_cache_hit(labels) }

    let(:labels) { {} }

    it 'increments number of hits' do
      expect(counter_mock)
        .to receive(:increment)
        .with(
          {
            cache_identifier: cache_identifier,
            feature_category: feature_category,
            backing_resource: backing_resource,
            cache_hit: true
          }
        ).once

      subject
    end

    context 'when labels redefine defaults' do
      let(:labels) { { backing_resource: :gitaly } }

      it 'increments number of hits' do
        expect(counter_mock)
          .to receive(:increment)
          .with(
            {
              backing_resource: :gitaly,
              cache_identifier: cache_identifier,
              feature_category: feature_category,
              cache_hit: true
            }
          ).once

        subject
      end
    end
  end

  describe '#increment_cache_miss' do
    subject { metrics.increment_cache_miss(labels) }

    let(:labels) { {} }

    it 'increments number of misses' do
      expect(counter_mock)
        .to receive(:increment)
        .with(
          {
            cache_identifier: cache_identifier,
            feature_category: feature_category,
            backing_resource: backing_resource,
            cache_hit: false
          }
        ).once

      subject
    end

    context 'when labels redefine defaults' do
      let(:labels) { { backing_resource: :gitaly } }

      it 'increments number of misses' do
        expect(counter_mock)
          .to receive(:increment)
          .with(
            {
              backing_resource: :gitaly,
              cache_identifier: cache_identifier,
              feature_category: feature_category,
              cache_hit: false
            }
          ).once

        subject
      end
    end
  end

  describe '#observe_cache_generation' do
    subject do
      metrics.observe_cache_generation(labels) { action }
    end

    let(:action) { 'action' }
    let(:histogram_mock) { instance_double(Prometheus::Client::Histogram) }
    let(:labels) { {} }

    before do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100.0, 500.0)

      allow(Gitlab::Metrics).to receive(:histogram).with(
        :redis_cache_generation_duration_seconds,
        'Duration of Redis cache generation',
        {
          cache_identifier: cache_identifier,
          feature_category: feature_category,
          backing_resource: backing_resource
        },
        [0, 1, 5]
      ).and_return(histogram_mock)
    end

    it 'updates histogram metric' do
      expect(histogram_mock).to receive(:observe).with(
        {
          cache_identifier: cache_identifier,
          feature_category: feature_category,
          backing_resource: backing_resource
        },
        400.0
      )

      is_expected.to eq(action)
    end

    context 'when labels redefine defaults' do
      let(:labels) { { backing_resource: :gitaly } }

      it 'updates histogram metric' do
        expect(histogram_mock).to receive(:observe).with(
          {
            cache_identifier: cache_identifier,
            feature_category: feature_category,
            backing_resource: :gitaly
          },
          400.0
        )

        is_expected.to eq(action)
      end
    end
  end
end
