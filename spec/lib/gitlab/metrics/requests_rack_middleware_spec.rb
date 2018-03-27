require 'spec_helper'

describe Gitlab::Metrics::RequestsRackMiddleware do
  let(:app) { double('app') }
  subject { described_class.new(app) }

  describe '#call' do
    let(:status) { 100 }
    let(:env) { { 'REQUEST_METHOD' => 'GET' } }
    let(:stack_result) { [status, {}, 'body'] }

    before do
      allow(app).to receive(:call).and_return(stack_result)
    end

    context '@app.call succeeds with 200' do
      before do
        allow(app).to receive(:call).and_return([200, nil, nil])
      end

      it 'increments requests count' do
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get')

        subject.call(env)
      end

      RSpec::Matchers.define :a_positive_execution_time do
        match { |actual| actual > 0 }
      end

      it 'measures execution time' do
        expect(described_class).to receive_message_chain(:http_request_duration_seconds, :observe).with({ status: 200, method: 'get' }, a_positive_execution_time)

        Timecop.scale(3600) { subject.call(env) }
      end
    end

    context '@app.call throws exception' do
      let(:http_request_duration_seconds) { double('http_request_duration_seconds') }

      before do
        allow(app).to receive(:call).and_raise(StandardError)
        allow(described_class).to receive(:http_request_duration_seconds).and_return(http_request_duration_seconds)
      end

      it 'increments exceptions count' do
        expect(described_class).to receive_message_chain(:rack_uncaught_errors_count, :increment)

        expect { subject.call(env) }.to raise_error(StandardError)
      end

      it 'increments requests count' do
        expect(described_class).to receive_message_chain(:http_request_total, :increment).with(method: 'get')

        expect { subject.call(env) }.to raise_error(StandardError)
      end

      it "does't measure request execution time" do
        expect(described_class.http_request_duration_seconds).not_to receive(:increment)

        expect { subject.call(env) }.to raise_error(StandardError)
      end
    end
  end
end
