# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Mcp::Handlers::InitializeRequest, feature_category: :mcp_server do
  let_it_be(:current_user) { create(:user) }
  let(:protocol_version) { '2025-06-18' }
  let(:params) { { protocolVersion: protocol_version } }
  let(:logger) { instance_double(Gitlab::Mcp::Logger) }

  subject(:handler) { described_class.new(params, nil, current_user) }

  before do
    allow(Gitlab::Mcp::Logger).to receive(:build).and_return(logger)
    allow(logger).to receive(:conditional_info)
  end

  it 'falls back to a version it supports' do
    expect(described_class::HANDSHAKE_PROTOCOL_VERSIONS)
      .to include(described_class::LATEST_HANDSHAKE_PROTOCOL_VERSION)
  end

  describe '#invoke' do
    it 'tracks the initialize event with the negotiated protocol version' do
      expect { handler.invoke }
        .to trigger_internal_events('initialize_mcp_connection')
        .with(user: current_user, additional_properties: { protocol_version: '2025-06-18' })
        .and increment_usage_metrics(
          'counts.count_total_initialize_mcp_connection_weekly',
          'counts.count_total_initialize_mcp_connection_monthly',
          'counts.count_total_initialize_mcp_connection',
          'redis_hll_counters.count_distinct_user_id_from_initialize_mcp_connection_weekly',
          'redis_hll_counters.count_distinct_user_id_from_initialize_mcp_connection_monthly'
        )
    end

    it 'logs the initialize request' do
      handler.invoke

      expect(logger).to have_received(:conditional_info).with(
        current_user,
        message: 'MCP initialize',
        event_name: 'initialize',
        ai_component: 'mcp_server',
        requested_protocol_version: '2025-06-18',
        protocol_version: '2025-06-18'
      )
    end

    context 'when the client requests a stateless protocol version' do
      let(:protocol_version) { '2026-07-28' }

      it 'tracks the negotiated handshake version, not the requested one' do
        expect { handler.invoke }
          .to trigger_internal_events('initialize_mcp_connection')
          .with(user: current_user, additional_properties: { protocol_version: '2025-11-25' })
      end

      it 'logs both the requested and the negotiated version' do
        handler.invoke

        expect(logger).to have_received(:conditional_info).with(
          current_user,
          hash_including(requested_protocol_version: '2026-07-28', protocol_version: '2025-11-25')
        )
      end
    end

    context 'when the protocol version is unsupported' do
      let(:protocol_version) { '2020-01-01' }

      it 'raises without tracking or logging' do
        expect { expect { handler.invoke }.to raise_error(ArgumentError) }
          .not_to trigger_internal_events('initialize_mcp_connection')
        expect(logger).not_to have_received(:conditional_info)
      end
    end

    context 'when the protocol version is missing' do
      let(:params) { {} }

      it 'raises without tracking or logging' do
        expect { expect { handler.invoke }.to raise_error(ArgumentError) }
          .not_to trigger_internal_events('initialize_mcp_connection')
        expect(logger).not_to have_received(:conditional_info)
      end
    end
  end
end
