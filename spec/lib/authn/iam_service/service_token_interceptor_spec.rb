# frozen_string_literal: true

require 'fast_spec_helper'
require 'grpc'

RSpec.describe Authn::IamService::ServiceTokenInterceptor, feature_category: :system_access do
  subject(:interceptor) { described_class.new(header: 'x-test-service-token', token: 'secret-value') }

  describe '.build_from' do
    it 'returns nil when credentials is nil' do
      expect(described_class.build_from(nil)).to be_nil
    end

    it 'builds an interceptor from a header/token credentials hash' do
      built = described_class.build_from(header: 'x-test-service-token', token: 'secret-value')

      expect(built).to be_an_instance_of(described_class)
    end
  end

  {
    request_response: :request,
    server_streamer: :request,
    client_streamer: :requests,
    bidi_streamer: :requests
  }.each do |call_type, request_kwarg|
    describe "##{call_type}" do
      it 'sets the header on the given metadata and yields', :aggregate_failures do
        metadata = { 'other-header' => 'unchanged' }
        yielded = false

        interceptor.public_send(call_type, request_kwarg => nil, call: nil, method: nil, metadata: metadata) do
          yielded = true
        end

        expect(metadata).to eq('other-header' => 'unchanged', 'x-test-service-token' => 'secret-value')
        expect(yielded).to be(true)
      end
    end
  end
end
