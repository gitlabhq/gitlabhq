# frozen_string_literal: true
require 'fast_spec_helper'
require 'rack'
require 'request_store'
require_relative '../../../support/helpers/next_instance_of'

describe Gitlab::Middleware::RequestContext do
  include NextInstanceOf

  let(:app) { -> (env) {} }
  let(:env) { {} }

  around do |example|
    RequestStore.begin!
    example.run
    RequestStore.end!
    RequestStore.clear!
  end

  describe '#call' do
    context 'setting the client ip' do
      subject { Gitlab::RequestContext.instance.client_ip }

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
          endpoint = proc do
            [200, {}, ["Hello"]]
          end

          described_class.new(endpoint).call(env)

          expect(subject).to eq(load_balancer_ip)
        end
      end

      context 'request' do
        let(:ip) { '192.168.1.11' }

        before do
          allow_next_instance_of(Rack::Request) do |instance|
            allow(instance).to receive(:ip).and_return(ip)
          end
          described_class.new(app).call(env)
        end

        it { is_expected.to eq(ip) }
      end

      context 'before RequestContext middleware run' do
        it { is_expected.to be_nil }
      end
    end
  end

  context 'setting the thread cpu time' do
    it 'sets the `start_thread_cpu_time`' do
      expect { described_class.new(app).call(env) }
        .to change { Gitlab::RequestContext.instance.start_thread_cpu_time }.from(nil).to(Float)
    end
  end

  context 'setting the request start time' do
    it 'sets the `request_start_time`' do
      expect { described_class.new(app).call(env) }
        .to change { Gitlab::RequestContext.instance.request_start_time }.from(nil).to(Float)
    end
  end
end
