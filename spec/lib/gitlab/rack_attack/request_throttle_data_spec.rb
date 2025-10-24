# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack::RequestThrottleData, feature_category: :rate_limiting do
  let(:throttle_data) do
    described_class.new(
      name: 'throttle_unauthenticated',
      period: 3600,
      limit: 3600,
      observed: 3700,
      now: Time.utc(2021, 1, 5, 10, 29, 30).to_i
    )
  end

  describe '#rounded_limit' do
    it 'normalizes limit to 60-second window' do
      expect(throttle_data.rounded_limit).to eq(60)
    end

    context 'with different periods' do
      it 'rounds up correctly for 120-second period' do
        data = described_class.new(
          name: 'test',
          period: 120,
          limit: 100,
          observed: 0,
          now: Time.now.to_i
        )
        expect(data.rounded_limit).to eq(50)
      end

      it 'rounds up correctly for 15-second period' do
        data = described_class.new(
          name: 'test',
          period: 15,
          limit: 10,
          observed: 0,
          now: Time.now.to_i
        )
        expect(data.rounded_limit).to eq(40)
      end
    end
  end

  describe '#remaining' do
    it 'calculates remaining quota when under limit' do
      data = described_class.new(
        name: 'test',
        period: 60,
        limit: 100,
        observed: 30,
        now: Time.now.to_i
      )
      expect(data.remaining).to eq(70)
    end

    it 'returns 0 when at limit' do
      data = described_class.new(
        name: 'test',
        period: 60,
        limit: 100,
        observed: 100,
        now: Time.now.to_i
      )
      expect(data.remaining).to eq(0)
    end

    it 'returns 0 when over limit' do
      expect(throttle_data.remaining).to eq(0)
    end
  end

  describe '#retry_after' do
    it 'calculates seconds until reset' do
      expect(throttle_data.retry_after).to eq(1830) # 30 minutes 30 seconds
    end

    it 'returns full period at start of window' do
      data = described_class.new(
        name: 'test',
        period: 3600,
        limit: 100,
        observed: 50,
        now: Time.utc(2021, 1, 5, 10, 0, 0).to_i
      )
      expect(data.retry_after).to eq(3600)
    end

    it 'returns 1 second at end of window' do
      data = described_class.new(
        name: 'test',
        period: 3600,
        limit: 100,
        observed: 50,
        now: Time.utc(2021, 1, 5, 10, 59, 59).to_i
      )
      expect(data.retry_after).to eq(1)
    end
  end

  describe '#reset_time' do
    it 'calculates correct reset time' do
      expect(throttle_data.reset_time).to eq(Time.utc(2021, 1, 5, 11, 0, 0))
    end
  end

  describe '.from_rack_attack' do
    let(:match_data) do
      {
        discriminator: '127.0.0.1',
        count: 3700,
        period: 1.hour,
        limit: 3600,
        epoch_time: Time.utc(2021, 1, 5, 10, 29, 30).to_i
      }
    end

    it 'creates ThrottleRequestData from Rack::Attack data' do
      data = described_class.from_rack_attack('throttle_unauthenticated', match_data)

      expect(data.name).to eq('throttle_unauthenticated')
      expect(data.period).to eq(3600)
      expect(data.limit).to eq(3600)
      expect(data.observed).to eq(3700)
      expect(data.now).to eq(Time.utc(2021, 1, 5, 10, 29, 30).to_i)
    end

    context 'when name is nil' do
      it 'returns nil and logs a warning' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          class: 'Gitlab::RackAttack::RequestThrottleData',
          message: '.from_rack_attack called with nil throttle name'
        )

        result = described_class.from_rack_attack(nil, match_data)

        expect(result).to be_nil
      end
    end

    context 'when required keys are missing' do
      it 'returns nil and logs a warning when count is missing' do
        incomplete_data = match_data.except(:count)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          class: 'Gitlab::RackAttack::RequestThrottleData',
          message: /.from_rack_attack called with incomplete data/
        )

        result = described_class.from_rack_attack('throttle_unauthenticated', incomplete_data)

        expect(result).to be_nil
      end

      it 'returns nil and logs a warning when multiple keys are missing' do
        incomplete_data = match_data.except(:count, :limit, :epoch_time)

        expect(Gitlab::AppLogger).to receive(:warn).with(
          class: 'Gitlab::RackAttack::RequestThrottleData',
          message: /.from_rack_attack called with incomplete data/
        )

        result = described_class.from_rack_attack('throttle_unauthenticated', incomplete_data)

        expect(result).to be_nil
      end
    end
  end

  describe '#common_response_headers' do
    it 'generates all common headers' do
      headers = throttle_data.common_response_headers

      expect(headers).to eq({
        'RateLimit-Name' => 'throttle_unauthenticated',
        'RateLimit-Limit' => '60',
        'RateLimit-Observed' => '3700',
        'RateLimit-Remaining' => '0',
        'RateLimit-Reset' => '1609844400'
      })
    end

    it 'does not include Retry-After' do
      headers = throttle_data.common_response_headers
      expect(headers).not_to have_key('Retry-After')
    end

    it 'does not include RateLimit-ResetTime' do
      headers = throttle_data.common_response_headers
      expect(headers).not_to have_key('RateLimit-ResetTime')
    end
  end

  describe '#throttled_response_headers' do
    it 'includes all headers including Retry-After' do
      headers = throttle_data.throttled_response_headers

      expect(headers).to eq({
        'RateLimit-Name' => 'throttle_unauthenticated',
        'RateLimit-Limit' => '60',
        'RateLimit-Observed' => '3700',
        'RateLimit-Remaining' => '0',
        'RateLimit-Reset' => '1609844400',
        'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
        'Retry-After' => '1830'
      })
    end
  end
end
