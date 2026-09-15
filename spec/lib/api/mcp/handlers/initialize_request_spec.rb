# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Mcp::Handlers::InitializeRequest, feature_category: :mcp_server do
  it 'falls back to a version it supports' do
    expect(described_class::HANDSHAKE_PROTOCOL_VERSIONS)
      .to include(described_class::LATEST_HANDSHAKE_PROTOCOL_VERSION)
  end
end
