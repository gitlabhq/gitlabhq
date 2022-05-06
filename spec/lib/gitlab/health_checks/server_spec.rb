# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HealthChecks::Server do
  context 'with running server thread' do
    subject(:server) { described_class.new(address: 'localhost', port: 8082) }

    before do
      # We need to send a request to localhost
      WebMock.allow_net_connect!

      server.start
    end

    after do
      webmock_enable!

      server.stop
    end

    shared_examples 'serves health check at' do |path|
      it 'responds with 200 OK' do
        response = Gitlab::HTTP.try_get("http://localhost:8082/#{path}", allow_local_requests: true)

        expect(response.code).to eq(200)
      end
    end

    describe '/readiness' do
      it_behaves_like 'serves health check at', 'readiness'
    end

    describe '/liveness' do
      it_behaves_like 'serves health check at', 'liveness'
    end

    describe 'other routes' do
      it 'serves 404' do
        response = Gitlab::HTTP.try_get("http://localhost:8082/other", allow_local_requests: true)

        expect(response.code).to eq(404)
      end
    end
  end

  context 'when server thread goes away' do
    before do
      expect_next_instance_of(::WEBrick::HTTPServer) do |webrick|
        allow(webrick).to receive(:start)
        expect(webrick).to receive(:listeners).and_call_original
      end
    end

    specify 'stop closes TCP socket' do
      server = described_class.new(address: 'localhost', port: 8082)
      server.start

      expect(server.thread).to receive(:alive?).and_return(false).at_least(:once)

      server.stop
    end
  end
end
