# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataMetrics, :with_license, feature_category: :service_ping do
  describe '.uncached_data' do
    subject { described_class.uncached_data }

    around do |example|
      described_class.instance_variable_set(:@definitions, nil)
      example.run
      described_class.instance_variable_set(:@definitions, nil)
    end

    before do
      allow_next_instance_of(Gitlab::Database::BatchCounter) do |batch_counter|
        allow(batch_counter).to receive(:transaction_open?).and_return(false)
      end

      allow_next_instance_of(Gitlab::Database::BatchAverageCounter) do |instance|
        allow(instance).to receive(:transaction_open?).and_return(false)
      end
    end

    context 'with instrumentation_class' do
      it 'includes top level keys' do
        expect(subject).to include(:uuid)
        expect(subject).to include(:hostname)
      end

      it 'includes counts keys', :aggregate_failures do
        expect(subject[:counts]).to include(:boards)
        expect(subject[:counts]).to include(:issues)
        expect(subject[:counts]).to include(:gitlab_for_jira_app_direct_installations)
        expect(subject[:counts]).to include(:gitlab_for_jira_app_proxy_installations)
      end

      it 'includes usage_activity_by_stage keys' do
        expect(subject[:usage_activity_by_stage][:plan]).to include(:issues)
      end

      it 'includes usage_activity_by_stage metrics' do
        expect(subject[:usage_activity_by_stage][:manage]).to include(:count_user_auth)
      end

      it 'includes usage_activity_by_stage_monthly keys' do
        expect(subject[:usage_activity_by_stage_monthly][:plan]).to include(:issues)
      end

      it 'includes settings keys' do
        expect(subject[:settings]).to include(:allow_runner_registration_token, :collected_data_categories)
      end

      describe 'Redis_HLL_counters' do
        let(:metric_files_key_paths) do
          Gitlab::Usage::MetricDefinition
            .definitions
            .select do |_, v|
              (v.data_source == 'redis_hll' || v.data_source == 'internal_events') &&
                v.key_path.starts_with?('redis_hll_counters') &&
                v.available?
            end
            .keys
            .sort
        end

        # Recursively traverse nested Hash of a generated Service Ping to return an Array of key paths
        # in the dotted format used in metric definition YAML files, e.g.: 'count.category.metric_name'
        def parse_service_ping_keys(object, key_path = [])
          if object.is_a?(Hash)
            object.each_with_object([]) do |(key, value), result|
              result.append parse_service_ping_keys(value, key_path + [key])
            end
          else
            key_path.join('.')
          end
        end

        let(:service_ping_key_paths) do
          parse_service_ping_keys(subject)
            .flatten
            .select { |k| k.starts_with?('redis_hll_counters') }
            .sort
        end

        it 'is included in the Service Ping hash structure' do
          expect(metric_files_key_paths).to match_array(service_ping_key_paths)
        end
      end
    end
  end
end
