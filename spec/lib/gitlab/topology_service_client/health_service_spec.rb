# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::TopologyServiceClient::HealthService, feature_category: :cell do
  subject(:cell_service) { described_class.new }

  let(:service_class) { Grpc::Health::V1::Health::Stub }
  let(:grpc_health_check_request_class) { Grpc::Health::V1::HealthCheckRequest }
  let(:grpc_health_check_response_class) { Grpc::Health::V1::HealthCheckResponse }

  describe '#service_healthy?' do
    before do
      allow(Gitlab.config.cell).to receive(:enabled).and_return(configured_cell)
    end

    context 'when topology service is disabled' do
      let(:configured_cell) { false }

      it 'raises an error when topology service is not enabled' do
        expect(Gitlab.config.cell).to receive(:enabled).and_return(false)

        expect { cell_service }.to raise_error(NotImplementedError)
      end
    end

    context 'when topology service is enabled' do
      let(:configured_cell) { true }

      before do
        allow_next_instance_of(service_class) do |instance|
          allow(instance).to receive(:check).with(instance_of(grpc_health_check_request_class)).and_return(
            grpc_health_check_response_class.new(status: grpc_status)
          )
        end
      end

      context 'when gRPC status is SERVING' do
        let(:grpc_status) { :SERVING }

        it { expect(cell_service.service_healthy?).to be(true) }
      end

      context 'when gRPC status is NOT_SERVING' do
        let(:grpc_status) { :NOT_SERVING }

        it { expect(cell_service.service_healthy?).to be(false) }
      end

      context 'when gRPC status is UNKNOWN' do
        let(:grpc_status) { :UNKNOWN }

        it { expect(cell_service.service_healthy?).to be(false) }
      end
    end

    context 'when topology service is unavailable' do
      let(:configured_cell) { true }

      before do
        allow_next_instance_of(service_class) do |instance|
          allow(instance).to receive(:check).with(instance_of(grpc_health_check_request_class)).and_raise(
            GRPC::Unavailable
          )
        end
      end

      it { expect(cell_service.service_healthy?).to be(false) }
    end
  end
end
