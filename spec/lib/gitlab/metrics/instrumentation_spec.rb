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
        allow(Gitlab::Metrics).to receive(:method_call_threshold).
          and_return(0)

        allow(described_class).to receive(:transaction).
          and_return(transaction)

        expect(transaction).to receive(:increment).
          with(:method_duration, a_kind_of(Numeric))

        expect(transaction).to receive(:add_metric).
          with(described_class::SERIES, an_instance_of(Hash),
               method: 'Dummy.foo')

        @dummy.foo
      end

      it 'does not track method calls below a given duration threshold' do
        allow(Gitlab::Metrics).to receive(:method_call_threshold).
          and_return(100)

        expect(transaction).to_not receive(:add_metric)

        @dummy.foo
      end

      it 'generates a method with the correct arity when using methods without arguments' do
        dummy = Class.new do
          def self.test; end
        end

        described_class.instrument_method(dummy, :test)

        expect(dummy.method(:test).arity).to eq(0)
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
        allow(Gitlab::Metrics).to receive(:method_call_threshold).
          and_return(0)

        allow(described_class).to receive(:transaction).
          and_return(transaction)

        expect(transaction).to receive(:increment).
          with(:method_duration, a_kind_of(Numeric))

        expect(transaction).to receive(:add_metric).
          with(described_class::SERIES, an_instance_of(Hash),
               method: 'Dummy#bar')

        @dummy.new.bar
      end

      it 'does not track method calls below a given duration threshold' do
        allow(Gitlab::Metrics).to receive(:method_call_threshold).
          and_return(100)

        expect(transaction).to_not receive(:add_metric)

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

  describe '.instrument_class_hierarchy' do
    before do
      allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)

      @child1 = Class.new(@dummy) do
        def self.child1_foo; end
        def child1_bar; end
      end

      @child2 = Class.new(@child1) do
        def self.child2_foo; end
        def child2_bar; end
      end
    end

    it 'recursively instruments a class hierarchy' do
      described_class.instrument_class_hierarchy(@dummy)

      expect(@child1).to respond_to(:_original_child1_foo)
      expect(@child2).to respond_to(:_original_child2_foo)

      expect(@child1.method_defined?(:_original_child1_bar)).to eq(true)
      expect(@child2.method_defined?(:_original_child2_bar)).to eq(true)
    end

    it 'does not instrument the root module' do
      described_class.instrument_class_hierarchy(@dummy)

      expect(@dummy).to_not respond_to(:_original_foo)
      expect(@dummy.method_defined?(:_original_bar)).to eq(false)
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

    it 'only instruments methods directly defined in the module' do
      mod = Module.new do
        def kittens
        end
      end

      @dummy.extend(mod)

      described_class.instrument_methods(@dummy)

      expect(@dummy).to_not respond_to(:_original_kittens)
    end

    it 'can take a block to determine if a method should be instrumented' do
      described_class.instrument_methods(@dummy) do
        false
      end

      expect(@dummy).to_not respond_to(:_original_foo)
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

    it 'only instruments methods directly defined in the module' do
      mod = Module.new do
        def kittens
        end
      end

      @dummy.include(mod)

      described_class.instrument_instance_methods(@dummy)

      expect(@dummy.method_defined?(:_original_kittens)).to eq(false)
    end

    it 'can take a block to determine if a method should be instrumented' do
      described_class.instrument_instance_methods(@dummy) do
        false
      end

      expect(@dummy.method_defined?(:_original_bar)).to eq(false)
    end
  end
end
