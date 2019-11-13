# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::HealthCheckService do
  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }

  subject { described_class.new(storage_name) }

  describe '#check' do
    it 'successfully sends a health check request' do
      expect(Gitlab::GitalyClient).to receive(:call).with(
        storage_name,
        :health_check,
        :check,
        instance_of(Grpc::Health::V1::HealthCheckRequest),
        timeout: Gitlab::GitalyClient.fast_timeout).and_call_original

      expect(subject.check).to eq({ success: true })
    end

    it 'receives an unsuccessful health check request' do
      expect_any_instance_of(Grpc::Health::V1::Health::Stub)
        .to receive(:check)
        .and_return(double(status: false))

      expect(subject.check).to eq({ success: false })
    end

    it 'gracefully handles gRPC error' do
      expect(Gitlab::GitalyClient).to receive(:call).with(
        storage_name,
        :health_check,
        :check,
        instance_of(Grpc::Health::V1::HealthCheckRequest),
        timeout: Gitlab::GitalyClient.fast_timeout)
          .and_raise(GRPC::Unavailable.new('Connection refused'))

      expect(subject.check).to eq({ success: false, message: '14:Connection refused' })
    end
  end
end
