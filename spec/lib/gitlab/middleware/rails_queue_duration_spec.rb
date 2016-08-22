require 'spec_helper'

describe Gitlab::Middleware::RailsQueueDuration do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:transaction) { double(:transaction) }

  before { expect(app).to receive(:call).with(env).and_return('yay') }

  describe '#call' do
    it 'calls the app when metrics are disabled' do
      expect(Gitlab::Metrics).to receive(:current_transaction).and_return(nil)
      expect(middleware.call(env)).to eq('yay')
    end

    context 'when metrics are enabled' do
      before { allow(Gitlab::Metrics).to receive(:current_transaction).and_return(transaction) }

      it 'calls the app when metrics are enabled but no timing header is found' do
        expect(middleware.call(env)).to eq('yay')
      end

      it 'sets proxy_flight_time and calls the app when the header is present' do
        env['HTTP_GITLAB_WORKHORSE_PROXY_START'] = '123'
        expect(transaction).to receive(:set).with(:rails_queue_duration, an_instance_of(Float))
        expect(middleware.call(env)).to eq('yay')
      end
    end
  end
end
