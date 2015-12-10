require 'spec_helper'

describe Gitlab::Metrics::Instrumentation do
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

  describe '.instrument_method' do
    describe 'with metrics enabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)

        Gitlab::Metrics::Instrumentation.instrument_method(@dummy, :foo)
      end

      it 'renames the original method' do
        expect(@dummy).to respond_to(:_original_foo)
      end

      it 'calls the instrumented method with the correct arguments' do
        expect(@dummy.foo).to eq('foo')
      end

      it 'fires an ActiveSupport notification upon calling the method' do
        expect(ActiveSupport::Notifications).to receive(:instrument).
          with('class_method.method_call', module: 'Dummy', name: :foo)

        @dummy.foo
      end
    end

    describe 'with metrics disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(false)
      end

      it 'does not instrument the method' do
        Gitlab::Metrics::Instrumentation.instrument_method(@dummy, :foo)

        expect(@dummy).to_not respond_to(:_original_foo)
      end
    end
  end

  describe '.instrument_instance_method' do
    describe 'with metrics enabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)

        Gitlab::Metrics::Instrumentation.
          instrument_instance_method(@dummy, :bar)
      end

      it 'renames the original method' do
        expect(@dummy.method_defined?(:_original_bar)).to eq(true)
      end

      it 'calls the instrumented method with the correct arguments' do
        expect(@dummy.new.bar).to eq('bar')
      end

      it 'fires an ActiveSupport notification upon calling the method' do
        expect(ActiveSupport::Notifications).to receive(:instrument).
          with('instance_method.method_call', module: 'Dummy', name: :bar)

        @dummy.new.bar
      end
    end

    describe 'with metrics disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(false)
      end

      it 'does not instrument the method' do
        Gitlab::Metrics::Instrumentation.
          instrument_instance_method(@dummy, :bar)

        expect(@dummy.method_defined?(:_original_bar)).to eq(false)
      end
    end
  end
end
