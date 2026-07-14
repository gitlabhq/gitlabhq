# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::ZoektRackMiddleware, feature_category: :global_search do
  let(:app) { double(:app, call: 'app call result') } # rubocop:disable RSpec/VerifiedDoubles -- mirrors elasticsearch_rack_middleware_spec.rb which has the same exception
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  describe '#call' do
    let(:zoekt_query_time) { 0.1 }
    let(:zoekt_requests_count) { 2 }

    before do
      allow(Gitlab::Instrumentation::Zoekt).to receive(:query_time) { zoekt_query_time }
      allow(Gitlab::Instrumentation::Zoekt).to receive(:get_request_count) { zoekt_requests_count }

      allow(Gitlab::Metrics).to receive(:current_transaction).and_return(transaction)
    end

    it 'calls the app' do
      expect(middleware.call(env)).to eq('app call result')
    end

    it 'records zoekt metrics' do
      expect(transaction).to receive(:increment).with(:http_zoekt_requests_total, zoekt_requests_count)
      expect(transaction).to receive(:observe).with(:http_zoekt_requests_duration_seconds, zoekt_query_time)

      middleware.call(env)
    end

    it 'records zoekt metrics if an error is raised' do
      expect(transaction).to receive(:increment).with(:http_zoekt_requests_total, zoekt_requests_count)
      expect(transaction).to receive(:observe).with(:http_zoekt_requests_duration_seconds, zoekt_query_time)

      allow(app).to receive(:call).with(env).and_raise(StandardError)

      expect { middleware.call(env) }.to raise_error(StandardError)
    end

    context 'when there are no zoekt requests' do
      let(:zoekt_requests_count) { 0 }

      it 'does not record any metrics' do
        expect(transaction).not_to receive(:observe).with(:http_zoekt_requests_duration_seconds)
        expect(transaction).not_to receive(:increment).with(:http_zoekt_requests_total, 0)

        middleware.call(env)
      end
    end
  end
end
