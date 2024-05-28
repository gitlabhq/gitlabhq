# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePingReport, :use_clean_rails_memory_store_caching, feature_category: :service_ping do
  include UsageDataHelpers

  let(:usage_data) { { uuid: "1111", counts: { issue: 0 } }.deep_stringify_keys }

  before do
    allow_next_instance_of(Gitlab::Usage::ServicePing::PayloadKeysProcessor) do |instance|
      allow(instance).to receive(:missing_key_paths).and_return([])
    end

    allow_next_instance_of(Gitlab::Usage::ServicePing::InstrumentedPayload) do |instance|
      allow(instance).to receive(:build).and_return({})
    end
  end

  context 'all_metrics_values' do
    it 'generates the service ping when there are no missing values' do
      expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)
      expect(described_class.for(output: :all_metrics_values)).to eq({ uuid: "1111", counts: { issue: 0 } }.deep_stringify_keys)
    end

    it 'generates the service ping with the missing values' do
      expect_next_instance_of(Gitlab::Usage::ServicePing::PayloadKeysProcessor, usage_data) do |instance|
        expect(instance).to receive(:missing_instrumented_metrics_key_paths).and_return(['counts.boards'])
      end

      expect_next_instance_of(Gitlab::Usage::ServicePing::InstrumentedPayload, ['counts.boards'], :with_value) do |instance|
        expect(instance).to receive(:build).and_return({ counts: { boards: 1 } })
      end

      expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)
      expect(described_class.for(output: :all_metrics_values)).to eq({ uuid: "1111", counts: { issue: 0, boards: 1 } }.deep_stringify_keys)
    end

    context 'with usage data payload with symbol keys and instrumented payload with string keys' do
      let(:usage_data) { { uuid: "1111", counts: { issue: 0 } } }

      it 'correctly merges string and symbol keys' do
        expect_next_instance_of(Gitlab::Usage::ServicePing::PayloadKeysProcessor, usage_data) do |instance|
          expect(instance).to receive(:missing_instrumented_metrics_key_paths).and_return(['counts.boards'])
        end

        expect_next_instance_of(Gitlab::Usage::ServicePing::InstrumentedPayload, ['counts.boards'], :with_value) do |instance|
          expect(instance).to receive(:build).and_return({ 'counts' => { 'boards' => 1 } })
        end

        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)
        expect(described_class.for(output: :all_metrics_values)).to eq({ uuid: "1111", counts: { issue: 0, boards: 1 } }.deep_stringify_keys)
      end
    end
  end

  context 'for output: :metrics_queries' do
    it 'generates the service ping' do
      expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

      described_class.for(output: :metrics_queries)
    end
  end

  context 'for output: :non_sql_metrics_values' do
    it 'generates the service ping' do
      expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

      described_class.for(output: :non_sql_metrics_values)
    end
  end

  context 'when using cached' do
    let(:new_usage_data) { { 'uuid' => '1112' } }
    let(:instrumented_payload) { { 'instrumented' => { 'metric' => 1 } } }
    let(:full_payload) { usage_data.merge(instrumented_payload) }
    let(:new_full_payload) { new_usage_data.merge(instrumented_payload) }

    before do
      allow_next_instance_of(Gitlab::Usage::ServicePing::InstrumentedPayload) do |instance|
        allow(instance).to receive(:build).and_return(instrumented_payload)
      end
    end

    context 'for cached: true' do
      it 'caches the values' do
        allow(Gitlab::UsageData).to receive(:data).and_return(usage_data, new_usage_data)

        expect(described_class.for(output: :all_metrics_values)).to eq(full_payload)
        expect(described_class.for(output: :all_metrics_values, cached: true)).to eq(full_payload)

        expect(Rails.cache.fetch('usage_data')).to eq(full_payload)
      end

      it 'writes to cache and returns fresh data' do
        allow(Gitlab::UsageData).to receive(:data).and_return(usage_data, new_usage_data)

        expect(described_class.for(output: :all_metrics_values)).to eq(full_payload)
        expect(described_class.for(output: :all_metrics_values)).to eq(new_full_payload)
        expect(described_class.for(output: :all_metrics_values, cached: true)).to eq(new_full_payload)

        expect(Rails.cache.fetch('usage_data')).to eq(new_full_payload)
      end
    end

    context 'when no caching' do
      it 'returns fresh data' do
        allow(Gitlab::UsageData).to receive(:data).and_return(usage_data, new_usage_data)

        expect(described_class.for(output: :all_metrics_values)).to eq(full_payload)
        expect(described_class.for(output: :all_metrics_values)).to eq(new_full_payload)

        expect(Rails.cache.fetch('usage_data')).to eq(new_full_payload)
      end
    end
  end

  context 'cross test values against queries' do
    def fetch_value_by_query(query)
      # Because test cases are run inside a transaction, if any query raise and error all queries that follows
      # it are automatically canceled by PostgreSQL, to avoid that problem, and to provide exhaustive information
      # about every metric, queries are wrapped explicitly in sub transactions.
      table_name = PgQuery.parse(query).tables.first
      gitlab_schema = Gitlab::Database::GitlabSchema.table_schema!(table_name)
      base_model = Gitlab::Database.schemas_to_base_models.fetch(gitlab_schema).first

      base_model.transaction do
        base_model.connection.execute(query)&.first&.values&.first
      end
    rescue ActiveRecord::StatementInvalid => e
      e.message
    end

    def build_payload_from_queries(payload, accumulator = [], key_path = [])
      payload.each do |key, value|
        if value.is_a?(Hash)
          build_payload_from_queries(value, accumulator, key_path.dup << key)
        elsif value.is_a?(String) && /SELECT .* FROM.*/ =~ value
          accumulator << [key_path.dup << key, value, fetch_value_by_query(value)]
        end
      end
      accumulator
    end

    def type_cast_to_defined_type(value, metric_definition)
      case metric_definition&.value_type
      when "string"
        value.to_s
      when "number"
        value.to_i
      when "object"
        case metric_definition&.json_schema&.fetch("type")
        when "array"
          value.to_a
        else
          value.to_h
        end
      else
        value
      end
    end

    before do
      stub_usage_data_connections
      stub_object_store_settings
      stub_prometheus_queries
      memoized_constatns = Gitlab::UsageData::CE_MEMOIZED_VALUES
      memoized_constatns += Gitlab::UsageData::EE_MEMOIZED_VALUES if defined? Gitlab::UsageData::EE_MEMOIZED_VALUES
      memoized_constatns.each { |v| Gitlab::UsageData.clear_memoization(v) }
      stub_database_flavor_check('Cloud SQL for PostgreSQL')
    end

    let(:service_ping_payload) { described_class.for(output: :all_metrics_values) }
    let(:metrics_queries_with_values) { build_payload_from_queries(described_class.for(output: :metrics_queries)) }
    let(:metric_definitions) { ::Gitlab::Usage::MetricDefinition.definitions }

    it 'generates queries that match collected data', :aggregate_failures do
      message = "Expected %{query} result to match %{value} for %{key_path} metric (got %{payload_value} instead)"

      metrics_queries_with_values.each do |key_path, query, value|
        metric_definition = metric_definitions[key_path.join('.')]

        # Skip broken metrics since they are usually overriden to return -1
        next if metric_definition&.broken?

        value = type_cast_to_defined_type(value, metric_definition)
        payload_value = service_ping_payload.dig(*key_path)

        expect(value).to(
          eq(payload_value),
          message % {
            query: query,
            value: (value || 'NULL'),
            payload_value: payload_value,
            key_path: key_path.join('.')
          }
        )
      end
    end
  end
end
