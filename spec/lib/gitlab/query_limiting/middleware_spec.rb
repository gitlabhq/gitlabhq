require 'spec_helper'

describe Gitlab::QueryLimiting::Middleware do
  describe '#call' do
    it 'runs the application with query limiting in place' do
      middleware = described_class.new(-> (env) { env })

      expect_any_instance_of(Gitlab::QueryLimiting::Transaction)
        .to receive(:act_upon_results)

      expect(middleware.call({ number: 10 }))
        .to eq({ number: 10 })
    end
  end

  describe '#action_name' do
    let(:middleware) { described_class.new(-> (env) { env }) }

    context 'using a Rails request' do
      it 'returns the name of the controller and action' do
        env = {
          described_class::CONTROLLER_KEY => double(
            :controller,
            action_name: 'show',
            class: double(:class, name: 'UsersController'),
            content_type: 'text/html'
          )
        }

        expect(middleware.action_name(env)).to eq('UsersController#show')
      end

      it 'includes the content type if this is not text/html' do
        env = {
          described_class::CONTROLLER_KEY => double(
            :controller,
            action_name: 'show',
            class: double(:class, name: 'UsersController'),
            content_type: 'application/json'
          )
        }

        expect(middleware.action_name(env))
          .to eq('UsersController#show (application/json)')
      end
    end

    context 'using a Grape API request' do
      it 'returns the name of the request method and endpoint path' do
        env = {
          described_class::ENDPOINT_KEY => double(
            :endpoint,
            route: double(:route, request_method: 'GET', path: '/foo')
          )
        }

        expect(middleware.action_name(env)).to eq('GET /foo')
      end

      it 'returns nil if the route can not be retrieved' do
        endpoint = double(:endpoint)
        env = { described_class::ENDPOINT_KEY => endpoint }

        allow(endpoint)
          .to receive(:route)
          .and_raise(RuntimeError)

        expect(middleware.action_name(env)).to be_nil
      end
    end
  end
end
