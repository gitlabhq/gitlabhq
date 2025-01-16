# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::RegisterJobService::Logger, feature_category: :continuous_integration do
  let_it_be(:runner) { build_stubbed(:ci_runner) }

  subject(:logger) { described_class.new(runner: runner) }

  describe '#instrument' do
    it "returns the block's value" do
      expect(logger.instrument(:expensive_operation) { 123 }).to eq(123)
    end

    it 'raises an error when block is not provided' do
      expect { logger.instrument(:expensive_operation) }
        .to raise_error(ArgumentError, 'block not given')
    end
  end

  describe '#commit' do
    subject(:commit) { logger.commit }

    before do
      freeze_time do
        stub_feature_flags(ci_register_job_instrumentation_logger: flag)
        allow(logger).to receive(:current_monotonic_time) { Time.current.to_i }

        logger.instrument(:process_queue, once: true) { travel(60.seconds) }
        logger.instrument(:process_build) { travel(10.seconds) }
        logger.instrument(:process_build) { travel(20.seconds) }
      end
    end

    context 'when the feature flag is enabled' do
      let(:flag) { true }

      let(:expected_data) do
        {
          class: described_class.name.to_s,
          message: 'RegisterJobService exceeded maximum duration',
          runner_id: runner.id,
          runner_type: runner.runner_type,
          process_queue_duration_s: 60,
          process_build_duration_s: {
            count: 2,
            max: 20,
            sum: 30
          }
        }
      end

      it 'logs to application.json' do
        expect(Gitlab::AppJsonLogger)
          .to receive(:info)
          .with(a_hash_including(expected_data))
          .and_call_original

        expect(commit).to be_truthy
      end

      context 'when the feature flag is disabled' do
        let(:flag) { false }

        it 'does not log' do
          expect(Gitlab::AppJsonLogger).not_to receive(:info)

          expect(commit).to be_falsey
        end
      end
    end
  end
end
