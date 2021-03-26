# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkerAttributes do
  let(:worker) do
    Class.new do
      def self.name
        "TestWorker"
      end

      include ApplicationWorker
    end
  end

  describe '.data_consistency' do
    context 'with valid data_consistency' do
      it 'returns correct data_consistency' do
        worker.data_consistency(:sticky)

        expect(worker.get_data_consistency).to eq(:sticky)
      end
    end

    context 'when data_consistency is not provided' do
      it 'defaults to :always' do
        expect(worker.get_data_consistency).to eq(:always)
      end
    end

    context 'with invalid data_consistency' do
      it 'raise exception' do
        expect { worker.data_consistency(:invalid) }
          .to raise_error('Invalid data consistency: invalid')
      end
    end

    context 'when job is idempotent' do
      context 'when data_consistency is not :always' do
        it 'raise exception' do
          worker.idempotent!

          expect { worker.data_consistency(:sticky) }
            .to raise_error("Class can't be marked as idempotent if data_consistency is not set to :always")
        end
      end

      context 'when feature_flag is provided' do
        before do
          stub_feature_flags(test_feature_flag: false)
          skip_feature_flags_yaml_validation
          skip_default_enabled_yaml_check
        end

        it 'returns correct feature flag value' do
          worker.data_consistency(:sticky, feature_flag: :test_feature_flag)

          expect(worker.get_data_consistency_feature_flag_enabled?).not_to be_truthy
        end
      end
    end
  end

  describe '.idempotent!' do
    context 'when data consistency is not :always' do
      it 'raise exception' do
        worker.data_consistency(:sticky)

        expect { worker.idempotent! }
          .to raise_error("Class can't be marked as idempotent if data_consistency is not set to :always")
      end
    end
  end
end
