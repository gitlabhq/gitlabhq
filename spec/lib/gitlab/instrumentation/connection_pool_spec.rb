# frozen_string_literal: true

require 'spec_helper'
require 'support/helpers/rails_helpers'

RSpec.describe Gitlab::Instrumentation::ConnectionPool, feature_category: :redis do
  before do
    ::ConnectionPool.prepend(::Gitlab::Instrumentation::ConnectionPool)
  end

  let(:option) { { name: 'test', size: 5 } }
  let(:pool) { ConnectionPool.new(option) { 'nothing' } }

  let_it_be(:size_gauge_args) { [:gitlab_connection_pool_size, 'Size of connection pool', {}, :all] }
  let_it_be(:available_gauge_args) do
    [:gitlab_connection_pool_available_count,
      'Number of available connections in the pool', {}, :all]
  end

  subject(:checkout_pool) { pool.checkout }

  describe '.checkout' do
    let(:size_gauge_double) { instance_double(::Prometheus::Client::Gauge) }

    context 'when tracking for the first time' do
      it 'initialises gauges' do
        expect(::Gitlab::Metrics).to receive(:gauge).with(*size_gauge_args).and_call_original
        expect(::Gitlab::Metrics).to receive(:gauge).with(*available_gauge_args).and_call_original

        checkout_pool
      end
    end

    it 'sets the size gauge only once' do
      expect(::Gitlab::Metrics.gauge(*size_gauge_args)).to receive(:set).with(
        { pool_name: 'test', connection_class: "String" }, 5).once

      checkout_pool
      checkout_pool
    end

    context 'when tracking on subsequent calls' do
      before do
        pool.checkout # initialise instance variables
      end

      it 'uses memoized gauges' do
        expect(::Gitlab::Metrics).not_to receive(:gauge).with(*size_gauge_args)
        expect(::Gitlab::Metrics).not_to receive(:gauge).with(*available_gauge_args)

        expect(pool.instance_variable_get(:@size_gauge)).not_to receive(:set)
          .with({ pool_name: 'test', connection_class: "String" }, 5)
        expect(pool.instance_variable_get(:@available_gauge)).to receive(:set)
          .with({ pool_name: 'test', connection_class: "String" }, 4)

        checkout_pool
      end

      context 'when pool name is omitted' do
        let(:option) { {} }

        it 'uses unknown name' do
          expect(pool.instance_variable_get(:@size_gauge)).not_to receive(:set)
            .with({ pool_name: 'unknown', connection_class: "String" }, 5)
          expect(pool.instance_variable_get(:@available_gauge)).to receive(:set)
            .with({ pool_name: 'unknown', connection_class: "String" }, 4)

          checkout_pool
        end
      end
    end
  end
end
