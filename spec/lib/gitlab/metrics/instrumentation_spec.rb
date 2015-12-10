require 'spec_helper'

describe Gitlab::Metrics::Instrumentation do
  let(:transaction) { Gitlab::Metrics::Transaction.new }

  before do
    @dummy = Class.new do
      def self.foo(text = 'foo')
        text
      end

      def bar(text = 'bar')
        text
      end
    end

    allow(@dummy).to receive(:name).and_return('Dummy')
  end

  describe '.configure' do
    it 'yields self' do
      described_class.configure do |c|
        expect(c).to eq(described_class)
      end
    end
  end

  describe '.instrument_method' do
    describe 'with metrics enabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)

        described_class.instrument_method(@dummy, :foo)
      end

      it 'renames the original method' do
        expect(@dummy).to respond_to(:_original_foo)
      end

      it 'calls the instrumented method with the correct arguments' do
        expect(@dummy.foo).to eq('foo')
      end

      it 'tracks the call duration upon calling the method' do
        allow(described_class).to receive(:transaction).
          and_return(transaction)

        expect(transaction).to receive(:add_metric).
          with(described_class::SERIES, an_instance_of(Hash),
               method: 'Dummy.foo')

        @dummy.foo
      end
    end

    describe 'with metrics disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(false)
      end

      it 'does not instrument the method' do
        described_class.instrument_method(@dummy, :foo)

        expect(@dummy).to_not respond_to(:_original_foo)
      end
    end
  end

  describe '.instrument_instance_method' do
    describe 'with metrics enabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)

        described_class.
          instrument_instance_method(@dummy, :bar)
      end

      it 'renames the original method' do
        expect(@dummy.method_defined?(:_original_bar)).to eq(true)
      end

      it 'calls the instrumented method with the correct arguments' do
        expect(@dummy.new.bar).to eq('bar')
      end

      it 'tracks the call duration upon calling the method' do
        allow(described_class).to receive(:transaction).
          and_return(transaction)

        expect(transaction).to receive(:add_metric).
          with(described_class::SERIES, an_instance_of(Hash),
               method: 'Dummy#bar')

        @dummy.new.bar
      end
    end

    describe 'with metrics disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(false)
      end

      it 'does not instrument the method' do
        described_class.
          instrument_instance_method(@dummy, :bar)

        expect(@dummy.method_defined?(:_original_bar)).to eq(false)
      end
    end
  end

  describe '.instrument_methods' do
    before do
      allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)
    end

    it 'instruments all public class methods' do
      described_class.instrument_methods(@dummy)

      expect(@dummy).to respond_to(:_original_foo)
    end
  end

  describe '.instrument_instance_methods' do
    before do
      allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)
    end

    it 'instruments all public instance methods' do
      described_class.instrument_instance_methods(@dummy)

      expect(@dummy.method_defined?(:_original_bar)).to eq(true)
    end
  end
end
