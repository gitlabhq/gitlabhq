require 'spec_helper'

describe Gitlab::Metrics::Subscribers::MethodCall do
  let(:transaction) { Gitlab::Metrics::Transaction.new }

  let(:subscriber) { described_class.new }

  let(:event) do
    double(:event, duration: 0.2, payload: { module: 'Foo', name: :foo })
  end

  before do
    allow(subscriber).to receive(:current_transaction).and_return(transaction)

    allow(Gitlab::Metrics).to receive(:last_relative_application_frame).
      and_return(['app/models/foo.rb', 4])
  end

  describe '#instance_method' do
    it 'tracks the execution of an instance method' do
      values = { duration: 0.2, file: 'app/models/foo.rb', line: 4 }

      expect(transaction).to receive(:add_metric).
        with(described_class::SERIES, values, method: 'Foo#foo')

      subscriber.instance_method(event)
    end
  end

  describe '#class_method' do
    it 'tracks the execution of a class method' do
      values = { duration: 0.2, file: 'app/models/foo.rb', line: 4 }

      expect(transaction).to receive(:add_metric).
        with(described_class::SERIES, values, method: 'Foo.foo')

      subscriber.class_method(event)
    end
  end
end
