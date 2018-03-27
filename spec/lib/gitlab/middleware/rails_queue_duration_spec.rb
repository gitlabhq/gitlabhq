require 'spec_helper'

describe Gitlab::Middleware::RailsQueueDuration do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  before do
    expect(app).to receive(:call).with(env).and_return('yay')
  end

  describe '#call' do
    it 'calls the app when metrics are disabled' do
      expect(Gitlab::Metrics).to receive(:current_transaction).and_return(nil)
      expect(middleware.call(env)).to eq('yay')
    end

    context 'when metrics are enabled' do
      before do
        allow(Gitlab::Metrics).to receive(:current_transaction).and_return(transaction)
      end

      it 'calls the app when metrics are enabled but no timing header is found' do
        expect(middleware.call(env)).to eq('yay')
      end

      it 'sets proxy_flight_time and calls the app when the header is present' do
        env['HTTP_GITLAB_WORKHORSE_PROXY_START'] = '123'
        expect(transaction).to receive(:set).with(:rails_queue_duration, an_instance_of(Float))
        expect(middleware.call(env)).to eq('yay')
      end

      it 'observes rails queue duration metrics and calls the app when the header is present' do
        env['HTTP_GITLAB_WORKHORSE_PROXY_START'] = '2000000000'

        expect(middleware.send(:metric_rails_queue_duration_seconds)).to receive(:observe).with(transaction.labels, 1)

        Timecop.freeze(Time.at(3)) do
          expect(middleware.call(env)).to eq('yay')
        end
      end
    end
  end
end
