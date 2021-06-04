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
    it 'sets `idempotent` attribute of the worker class to true' do
      worker.idempotent!

      expect(worker.send(:class_attributes)[:idempotent]).to eq(true)
    end

    context 'when data consistency is not :always' do
      it 'raise exception' do
        worker.data_consistency(:sticky)

        expect { worker.idempotent! }
          .to raise_error("Class can't be marked as idempotent if data_consistency is not set to :always")
      end
    end
  end

  describe '.idempotent?' do
    subject(:idempotent?) { worker.idempotent? }

    context 'when the worker is idempotent' do
      before do
        worker.idempotent!
      end

      it { is_expected.to be_truthy }
    end

    context 'when the worker is not idempotent' do
      it { is_expected.to be_falsey }
    end
  end

  describe '.deduplicate' do
    it 'sets deduplication_strategy and deduplication_options' do
      worker.deduplicate(:until_executing, including_scheduled: true)

      expect(worker.send(:class_attributes)[:deduplication_strategy]).to eq(:until_executing)
      expect(worker.send(:class_attributes)[:deduplication_options]).to eq(including_scheduled: true)
    end
  end

  describe '#deduplication_enabled?' do
    subject(:deduplication_enabled?) { worker.deduplication_enabled? }

    context 'when no feature flag is set' do
      before do
        worker.deduplicate(:until_executing)
      end

      it { is_expected.to eq(true) }
    end

    context 'when feature flag is set' do
      before do
        skip_feature_flags_yaml_validation
        skip_default_enabled_yaml_check

        worker.deduplicate(:until_executing, feature_flag: :my_feature_flag)
      end

      context 'when the FF is enabled' do
        before do
          stub_feature_flags(my_feature_flag: true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when the FF is disabled' do
        before do
          stub_feature_flags(my_feature_flag: false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end
end
