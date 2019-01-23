# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Tracing::GRPCInterceptor do
  subject { described_class.instance }

  shared_examples_for "a grpc interceptor method" do
    let(:custom_error) { Class.new(StandardError) }

    it 'yields' do
      expect { |b| method.call(kwargs, &b) }.to yield_control
    end

    it 'propagates exceptions' do
      expect { method.call(kwargs) { raise custom_error } }.to raise_error(custom_error)
    end
  end

  describe '#request_response' do
    let(:method) { subject.method(:request_response) }
    let(:kwargs) { { request: {}, call: {}, method: 'grc_method', metadata: {} } }

    it_behaves_like 'a grpc interceptor method'
  end

  describe '#client_streamer' do
    let(:method) { subject.method(:client_streamer) }
    let(:kwargs) { { requests: [], call: {}, method: 'grc_method', metadata: {} } }

    it_behaves_like 'a grpc interceptor method'
  end

  describe '#server_streamer' do
    let(:method) { subject.method(:server_streamer) }
    let(:kwargs) { { request: {}, call: {}, method: 'grc_method', metadata: {} } }

    it_behaves_like 'a grpc interceptor method'
  end

  describe '#bidi_streamer' do
    let(:method) { subject.method(:bidi_streamer) }
    let(:kwargs) { { requests: [], call: {}, method: 'grc_method', metadata: {} } }

    it_behaves_like 'a grpc interceptor method'
  end
end
