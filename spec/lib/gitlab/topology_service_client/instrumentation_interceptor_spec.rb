# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::InstrumentationInterceptor, feature_category: :cell do
  let(:interceptor) { described_class.new }
  let(:request) { Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateRequest.new }
  let(:call) { double('call') } # rubocop:disable RSpec/VerifiedDoubles -- No concrete class available for gRPC call
  let(:grpc_method) { '/gitlab.cells.topology_service.claims.v1.ClaimService/BeginUpdate' }

  before do
    allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0, 1.3)
    allow(Gitlab::Instrumentation::TopologyService).to receive(:add_call)
  end

  describe '#request_response' do
    def request_response(&block)
      interceptor.request_response(request: request, call: call, method: grpc_method, metadata: {}, &block)
    end

    context 'when the call succeeds' do
      let(:response) { Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new }

      it 'returns the response and records the call', :aggregate_failures do
        expect(request_response { response }).to eq(response)
        expect(Gitlab::Instrumentation::TopologyService)
          .to have_received(:add_call).with(request: request, duration: be_within(0.001).of(0.3))
      end
    end

    context 'when the call fails' do
      it 'records the call and raises the error again', :aggregate_failures do
        expect { request_response { raise GRPC::DeadlineExceeded } }.to raise_error(GRPC::DeadlineExceeded)
        expect(Gitlab::Instrumentation::TopologyService)
          .to have_received(:add_call).with(request: request, duration: be_within(0.001).of(0.3))
      end
    end
  end
end
