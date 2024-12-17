# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::HealthStatus::Indicators::PrometheusAlertIndicator, :aggregate_failures,
  feature_category: :database do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  let(:context) do
    Gitlab::Database::HealthStatus::Context.new(
      described_class,
      connection,
      ['users']
    )
  end

  let(:invalid_indicator) do
    Class.new(described_class).new(context)
  end

  let(:valid_indicator) do
    Class.new(described_class) do
      def enabled?
        true
      end

      def slo_key
        :test_indicator_slo
      end

      def sli_key
        :test_indicator_sli
      end
    end.new(context)
  end

  describe '#enabled?' do
    it 'throws NotImplementedError for invalid indicator' do
      expect { invalid_indicator.send(:enabled?) }.to raise_error(NotImplementedError)
    end

    it 'returns the defined value for valid indicator' do
      expect(valid_indicator.send(:enabled?)).to eq(true)
    end
  end

  describe '#slo_key' do
    it 'throws NotImplementedError for invalid indicator' do
      expect { invalid_indicator.send(:slo_key) }.to raise_error(NotImplementedError)
    end

    it 'returns the defined value for valid indicator' do
      expect(valid_indicator.send(:slo_key)).to eq(:test_indicator_slo)
    end
  end

  describe '#sli_key' do
    it 'throws NotImplementedError for invalid indicator' do
      expect { invalid_indicator.send(:sli_key) }.to raise_error(NotImplementedError)
    end

    it 'returns the defined value for valid indicator' do
      expect(valid_indicator.send(:sli_key)).to eq(:test_indicator_sli)
    end
  end
end
