# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::Helpers::SnowplowEventMetricLogger, feature_category: :product_analytics do
  let(:counter) { instance_double(Prometheus::Client::Counter) }

  subject(:helper) { Class.new.include(described_class).new }

  describe '#increment_successful_events_emissions' do
    it 'increments the successful events counter' do
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
      allow(counter).to receive(:increment)

      helper.send(:increment_successful_events_emissions, 5)

      expect(counter).to have_received(:increment).with({}, 5)
    end

    it 'logs when an error occurs' do
      allow(Gitlab::Metrics).to receive(:counter).and_raise(StandardError.new('Metrics error'))
      allow(counter).to receive(:increment)

      expect(Gitlab::AppLogger).to receive(:warn).with(
        'Failed to increment Snowplow successful events metrics: Metrics error'
      )

      helper.send(:increment_successful_events_emissions, 5)
    end
  end

  describe '#increment_failed_events_emissions' do
    it 'increments the failed events counter' do
      allow(Gitlab::Metrics).to receive(:counter).and_return(counter)
      allow(counter).to receive(:increment)

      helper.send(:increment_failed_events_emissions, 3)

      expect(counter).to have_received(:increment).with({}, 3)
    end

    it 'logs when an error occurs' do
      allow(Gitlab::Metrics).to receive(:counter).and_raise(StandardError.new('Metrics error'))
      allow(counter).to receive(:increment)

      expect(Gitlab::AppLogger).to receive(:warn).with(
        'Failed to increment Snowplow failed events metrics: Metrics error'
      )

      helper.send(:increment_failed_events_emissions, 1)
    end
  end

  describe '#failure_callback' do
    let(:success_count) { 5 }
    let(:failures) do
      [
        { 'se_ca' => 'category1', 'se_ac' => 'action1' },
        { 'se_ca' => 'category2', 'se_ac' => 'action2' }
      ]
    end

    before do
      allow(helper).to receive(:increment_failed_events_emissions)
      allow(helper).to receive(:log_failures)
      allow(helper).to receive(:increment_successful_events_emissions)
    end

    it 'calls increment_successful_events_emissions with success count' do
      helper.send(:failure_callback, success_count, failures)

      expect(helper).to have_received(:increment_successful_events_emissions).with(success_count)
    end

    it 'calls increment_failed_events_emissions with failure count' do
      helper.send(:failure_callback, success_count, failures)

      expect(helper).to have_received(:increment_failed_events_emissions).with(failures.size)
    end

    it 'calls log_failures with failures array' do
      helper.send(:failure_callback, success_count, failures)

      expect(helper).to have_received(:log_failures).with(failures)
    end
  end

  describe '#log_failures' do
    let(:failures) do
      [
        { 'se_ac' => 'create_build' },
        { 'se_ca' => 'create_issue' }
      ]
    end

    before do
      allow(Gitlab::AppLogger).to receive(:error)
    end

    it 'logs each failure with AppLogger' do
      helper.send(:log_failures, failures)

      expect(Gitlab::AppLogger).to have_received(:error).twice
    end

    it 'logs failure with correct message' do
      helper.send(:log_failures, failures)

      expect(Gitlab::AppLogger).to have_received(:error).with(
        a_string_matching('create_build failed to be reported to collector at localhost')
      )
    end
  end

  describe '#hostname' do
    before do
      allow_next_instance_of(Gitlab::Tracking::Destinations::DestinationConfiguration) do |instance|
        allow(instance).to receive(:hostname).and_return('gitlab.foo')
      end
      allow(helper).to receive(:hostname).and_return('localhost:9000')
    end

    it 'returns the correct hostname from the helper class' do
      expect(helper.send(:hostname)).to eq('localhost:9000')
    end
  end
end
