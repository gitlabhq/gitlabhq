# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::ServerService do
  let(:storage) { 'default' }

  describe '#readiness_check' do
    before do
      ::Gitlab::GitalyClient.clear_stubs!
    end

    let(:request) do
      Gitaly::ReadinessCheckRequest.new(timeout: 30)
    end

    subject(:readiness_check) { described_class.new(storage).readiness_check }

    it 'returns a positive success if no failures happened' do
      expect_next_instance_of(Gitaly::ServerService::Stub) do |service|
        response = Gitaly::ReadinessCheckResponse.new(ok_response: Gitaly::ReadinessCheckResponse::Ok.new)
        expect(service).to receive(:readiness_check).with(request, kind_of(Hash)).and_return(response)
      end

      expect(readiness_check[:success]).to eq(true)
    end

    it 'returns a negative success and a compiled message if at least one failure happened' do
      failure1 = Gitaly::ReadinessCheckResponse::Failure::Response.new(name: '1', error_message: 'msg 1')
      failure2 = Gitaly::ReadinessCheckResponse::Failure::Response.new(name: '2', error_message: 'msg 2')
      failures = Gitaly::ReadinessCheckResponse::Failure.new(failed_checks: [failure1, failure2])
      response = Gitaly::ReadinessCheckResponse.new(failure_response: failures)

      expect_next_instance_of(Gitaly::ServerService::Stub) do |service|
        expect(service).to receive(:readiness_check).with(request, kind_of(Hash)).and_return(response)
      end

      expect(readiness_check[:success]).to eq(false)
      expect(readiness_check[:message]).to eq("1: msg 1\n2: msg 2")
    end
  end
end
