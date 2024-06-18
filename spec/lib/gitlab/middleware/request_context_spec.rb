# frozen_string_literal: true
require 'spec_helper'
require 'rack'
require 'request_store'
require 'gitlab/rspec/next_instance_of'

RSpec.describe Gitlab::Middleware::RequestContext, feature_category: :application_instrumentation do
  include NextInstanceOf

  let(:app) { ->(env) {} }
  let(:env) { {} }

  around do |example|
    RequestStore.begin!
    example.run
    RequestStore.end!
    RequestStore.clear!
  end

  describe '#call' do
    let(:instance) { Gitlab::RequestContext.instance }

    subject { described_class.new(app).call(env) }

    context 'setting the client ip' do
      context 'with X-Forwarded-For headers' do
        let(:load_balancer_ip) { '1.2.3.4' }
        let(:headers) do
          {
            'HTTP_X_FORWARDED_FOR' => "#{load_balancer_ip}, 127.0.0.1",
            'REMOTE_ADDR' => '127.0.0.1'
          }
        end

        let(:env) { Rack::MockRequest.env_for("/").merge(headers) }

        it 'returns the load balancer IP' do
          expect { subject }.to change { instance.client_ip }.from(nil).to(load_balancer_ip)
        end
      end

      context 'request' do
        let(:ip) { '192.168.1.11' }

        before do
          allow_next_instance_of(Rack::Request) do |request|
            allow(request).to receive(:ip).and_return(ip)
          end
        end

        it 'sets the `client_ip`' do
          expect { subject }.to change { instance.client_ip }.from(nil).to(ip)
        end

        it 'sets the `request_start_time`' do
          expect { subject }.to change { instance.request_start_time }.from(nil).to(Float)
        end

        it 'sets the `spam_params`' do
          expect { subject }.to change { instance.spam_params }.from(nil).to(::Spam::SpamParams)
        end
      end
    end
  end
end
