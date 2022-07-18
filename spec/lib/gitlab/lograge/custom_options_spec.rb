# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Lograge::CustomOptions do
  describe '.call' do
    let(:params) do
      {
        'controller' => 'ApplicationController',
        'action' => 'show',
        'format' => 'html',
        'a' => 'b'
      }
    end

    let(:event_payload) do
      {
        params: params,
        user_id: 'test',
        cf_ray: SecureRandom.hex,
        cf_request_id: SecureRandom.hex,
        metadata: { 'meta.user' => 'jane.doe' },
        request_urgency: :default,
        target_duration_s: 1,
        remote_ip: '192.168.1.2',
        ua: 'Nyxt',
        queue_duration_s: 0.2,
        etag_route: '/etag',
        response_bytes: 1234
      }
    end

    let(:event) { ActiveSupport::Notifications::Event.new('test', 1, 2, 'transaction_id', event_payload) }

    subject { described_class.call(event) }

    it 'ignores some parameters' do
      param_keys = subject[:params].map { |param| param[:key] }

      expect(param_keys).not_to include(*described_class::IGNORE_PARAMS)
    end

    it 'formats the parameters' do
      expect(subject[:params]).to eq([{ key: 'a', value: 'b' }])
    end

    it 'adds the current time' do
      travel_to(5.days.ago) do
        expected_time = Time.now.utc.iso8601(3)

        expect(subject[:time]).to eq(expected_time)
      end
    end

    it 'adds the user id' do
      expect(subject[:user_id]).to eq('test')
    end

    it 'adds the response length' do
      expect(subject[:response_bytes]).to eq(1234)
    end

    context 'with log_response_length disabled' do
      before do
        stub_feature_flags(log_response_length: false)
      end

      it 'does not add the response length' do
        expect(subject).not_to include(:response_bytes)
      end
    end

    it 'adds Cloudflare headers' do
      expect(subject[:cf_ray]).to eq(event.payload[:cf_ray])
      expect(subject[:cf_request_id]).to eq(event.payload[:cf_request_id])
    end

    it 'adds the metadata' do
      expect(subject['meta.user']).to eq('jane.doe')
    end

    context 'when metadata is missing' do
      let(:event_payload) { { params: {} } }

      it 'does not break' do
        expect { subject }.not_to raise_error
      end
    end

    context 'trusted payload' do
      it { is_expected.to include(event_payload.slice(*described_class::KNOWN_PAYLOAD_PARAMS)) }

      context 'payload with rejected fields' do
        let(:event_payload) { { params: {}, request_urgency: :high, something: 'random', username: nil } }

        it { is_expected.to include({ request_urgency: :high }) }
        it { is_expected.not_to include({ something: 'random' }) }
        it { is_expected.not_to include({ username: nil }) }
      end
    end

    context 'when correlation_id is overridden' do
      let(:correlation_id_key) { Labkit::Correlation::CorrelationId::LOG_KEY }

      before do
        event_payload[correlation_id_key] = '123456'
      end

      it 'sets the overridden value' do
        expect(subject[correlation_id_key]).to eq('123456')
      end
    end

    context 'when feature flags are present', :request_store do
      before do
        allow(Feature).to receive(:log_feature_flag_states?).and_return(false)

        [:enabled_feature, :disabled_feature].each do |flag_name|
          stub_feature_flag_definition(flag_name, log_state_changes: true)
          allow(Feature).to receive(:log_feature_flag_states?).with(flag_name).and_call_original
        end

        Feature.enable(:enabled_feature)
        Feature.disable(:disabled_feature)
      end

      context 'and :feature_flag_log_states is enabled' do
        before do
          Feature.enable(:feature_flag_state_logs)
        end

        it 'adds feature flag events' do
          Feature.enabled?(:enabled_feature)
          Feature.enabled?(:disabled_feature)

          expect(subject).to have_key(:feature_flag_states)
          expect(subject[:feature_flag_states]).to match_array(%w[enabled_feature:1 disabled_feature:0])
        end
      end

      context 'and :feature_flag_log_states is disabled' do
        before do
          Feature.disable(:feature_flag_state_logs)
        end

        it 'does not track or add feature flag events' do
          Feature.enabled?(:enabled_feature)
          Feature.enabled?(:disabled_feature)

          expect(subject).not_to have_key(:feature_flag_states)
          expect(Feature).not_to receive(:log_feature_flag_state)
        end
      end
    end
  end
end
