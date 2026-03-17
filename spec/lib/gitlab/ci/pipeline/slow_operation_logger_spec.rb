# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::SlowOperationLogger, :request_store, feature_category: :pipeline_composition do
  let(:test_class) do
    Class.new do
      include Gitlab::Ci::Pipeline::SlowOperationLogger

      def perform_operation(operation_name:, project:, context: {}, &block)
        log_slow_operation(operation_name: operation_name, project: project, context: context, &block)
      end
    end
  end

  let(:instance) { test_class.new }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  describe '#log_slow_operation' do
    let(:operation_name) { 'test_operation' }
    let(:context) { { project_id: project.id, user_id: user.id } }

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_slow_operation_logger: false)
      end

      it 'yields the block without logging' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        result = instance.perform_operation(operation_name: operation_name, project: project, context: context) do
          'result'
        end

        expect(result).to eq('result')
      end

      it 'does not capture counters' do
        expect(instance).not_to receive(:capture_instrumentation_counters)

        instance.perform_operation(operation_name: operation_name, project: project, context: context) { 'result' }
      end
    end

    context 'when operation duration is below threshold' do
      before do
        stub_const("#{described_class}::SLOW_THRESHOLD_SECONDS", 10.0)
      end

      it 'yields the block without logging' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        result = instance.perform_operation(operation_name: operation_name, project: project, context: context) do
          'result'
        end

        expect(result).to eq('result')
      end
    end

    context 'when operation duration exceeds threshold' do
      before do
        stub_const("#{described_class}::SLOW_THRESHOLD_SECONDS", 0.0)
      end

      it 'returns the block result' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        result = instance.perform_operation(operation_name: operation_name, project: project, context: context) do
          'expected_result'
        end

        expect(result).to eq('expected_result')
      end

      it 'captures instrumentation counters' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(a_hash_including(
          message: "CI slow operation alert for #{operation_name}",
          duration_s: a_kind_of(Numeric),
          db_main_count: 2,
          db_main_write_count: 0,
          db_main_cached_count: 0,
          gitaly_calls: 1,
          gitaly_duration_s: a_kind_of(Numeric),
          redis_calls: 6,
          redis_duration_s: a_kind_of(Numeric),
          project_id: project.id,
          user_id: user.id
        ))

        instance.perform_operation(operation_name: operation_name, project: project, context: context) do
          Project.find(project.id) # 1 DB call
          User.find(user.id) # 1 DB call
          project.repository.root_ref # 1 Gitaly call and 4 Redis calls
          Gitlab::Redis::Cache.with { |redis| redis.get('test_key1') }
          Gitlab::Redis::Cache.with { |redis| redis.get('test_key2') }
        end
      end
    end

    context 'when capture_instrumentation_counters raises an error' do
      before do
        stub_const("#{described_class}::SLOW_THRESHOLD_SECONDS", 0.0)
        allow(instance).to receive(:capture_instrumentation_counters).and_raise(StandardError.new('test error'))
      end

      it 'returns empty hash and continues execution without logging' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        result = instance.perform_operation(operation_name: operation_name, project: project, context: context) do
          'result'
        end

        expect(result).to eq('result')
      end
    end
  end
end
