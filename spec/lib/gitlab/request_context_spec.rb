# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::RequestContext do
  describe '#client_ip' do
    subject { described_class.client_ip }

    let(:app) { -> (env) {} }
    let(:env) { Hash.new }

    context 'with X-Forwarded-For headers', :request_store do
      let(:load_balancer_ip) { '1.2.3.4' }
      let(:headers) do
        {
          'HTTP_X_FORWARDED_FOR' => "#{load_balancer_ip}, 127.0.0.1",
          'REMOTE_ADDR' => '127.0.0.1'
        }
      end

      let(:env) { Rack::MockRequest.env_for("/").merge(headers) }

      it 'returns the load balancer IP' do
        client_ip = nil

        endpoint = proc do
          client_ip = Gitlab::SafeRequestStore[:client_ip]
          [200, {}, ["Hello"]]
        end

        described_class.new(endpoint).call(env)

        expect(client_ip).to eq(load_balancer_ip)
      end
    end

    context 'when RequestStore::Middleware is used' do
      around do |example|
        RequestStore::Middleware.new(-> (env) { example.run }).call({})
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
end
