# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataMetrics do
  describe '.uncached_data' do
    subject { described_class.uncached_data }

    around do |example|
      described_class.instance_variable_set(:@definitions, nil)
      example.run
      described_class.instance_variable_set(:@definitions, nil)
    end

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'with instrumentation_class' do
      it 'includes top level keys' do
        expect(subject).to include(:uuid)
        expect(subject).to include(:hostname)
      end

      it 'includes counts keys' do
        expect(subject[:counts]).to include(:boards)
      end

      describe 'Redis_HLL_counters' do
        # categories to be merged on future MR
        let(:ignored_metric_files_key_patterns) do
          %w(
            analytics
            ci_templates
            ecosystem
            deploy_token_packages
            user_packages
            epic_events
            snippets
            epics_usage
            network_policies
          ).freeze
        end

        let(:metric_files_key_paths) do
          Gitlab::Usage::MetricDefinition
            .definitions
            .select { |k, v| v.attributes[:data_source] == 'redis_hll' && v.key_path.starts_with?('redis_hll_counters') }
            .reject { |k, v| v.key_path =~ Regexp.union(ignored_metric_files_key_patterns) }
            .keys
            .sort
        end

        # Recursively traverse nested Hash of a generated Usage Ping to return an Array of key paths
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

        let(:usage_ping_key_paths) do
          parse_service_ping_keys(subject)
            .flatten
            .select { |k| k.starts_with?('redis_hll_counters') }
            .reject {|k| k =~ Regexp.union(ignored_metric_files_key_patterns) }
            .sort
        end

        it 'is included in the Usage Ping hash structure' do
          expect(metric_files_key_paths).to match_array(usage_ping_key_paths)
        end
      end

      it 'includes counts keys' do
        expect(subject[:counts]).to include(:issues)
      end

      it 'includes usage_activity_by_stage keys' do
        expect(subject[:usage_activity_by_stage][:plan]).to include(:issues)
      end

      it 'includes usage_activity_by_stage_monthly keys' do
        expect(subject[:usage_activity_by_stage_monthly][:plan]).to include(:issues)
      end

      it 'includes settings keys' do
        expect(subject[:settings]).to include(:collected_data_categories)
      end
    end
  end
end
