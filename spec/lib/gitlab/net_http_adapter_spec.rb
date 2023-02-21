# frozen_string_literal: true

require 'fast_spec_helper'
require 'net/http'

RSpec.describe Gitlab::NetHttpAdapter, feature_category: :api do
  describe '#connect' do
    let(:url) { 'https://example.org' }
    let(:net_http_adapter) { described_class.new(url) }

    subject(:connect) { net_http_adapter.send(:connect) }

    before do
      allow(TCPSocket).to receive(:open).and_return(Socket.new(:INET, :STREAM))
    end

    it 'uses a Gitlab::BufferedIo instance as @socket' do
      connect

      expect(net_http_adapter.instance_variable_get(:@socket)).to be_a(Gitlab::BufferedIo)
    end
  end
end
