require 'spec_helper'

describe Gitlab::Metrics::Instrumentation do
  let(:env) { {} }
  let(:transaction) { Gitlab::Metrics::WebTransaction.new(env) }

  before do
    @dummy = Class.new do
      def self.foo(text = 'foo')
        text
      end

      class << self
        def buzz(text = 'buzz')
          text
        end
        private :buzz

        def flaky(text = 'flaky')
          text
        end
        protected :flaky
      end

      def bar(text = 'bar')
        text
      end

      def wadus(text = 'wadus')
        text
      end
      private :wadus

      def chaf(text = 'chaf')
        text
      end
      protected :chaf
    end

    allow(@dummy).to receive(:name).and_return('Dummy')
  end

  describe '.series' do
    it 'returns a String' do
      expect(described_class.series).to be_an_instance_of(String)
    end
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

      it 'instruments the Class' do
        target = @dummy.singleton_class

        expect(described_class.instrumented?(target)).to eq(true)
      end

      it 'defines a proxy method' do
        mod = described_class.proxy_module(@dummy.singleton_class)

        expect(mod.method_defined?(:foo)).to eq(true)
      end

      it 'calls the instrumented method with the correct arguments' do
        expect(@dummy.foo).to eq('foo')
      end

      it 'tracks the call duration upon calling the method' do
        allow(Gitlab::Metrics).to receive(:method_call_threshold)
          .and_return(0)

        allow(described_class).to receive(:transaction)
          .and_return(transaction)

        expect_any_instance_of(Gitlab::Metrics::MethodCall).to receive(:measure)

        @dummy.foo
      end

      it 'does not track method calls below a given duration threshold' do
        allow(Gitlab::Metrics).to receive(:method_call_threshold)
          .and_return(100)

        expect(transaction).not_to receive(:add_metric)

        @dummy.foo
      end

      it 'generates a method with the correct arity when using methods without arguments' do
        dummy = Class.new do
          def self.test; end
        end

        described_class.instrument_method(dummy, :test)

        expect(dummy.method(:test).arity).to eq(0)
      end

      describe 'when a module is instrumented multiple times' do
        it 'calls the instrumented method with the correct arguments' do
          described_class.instrument_method(@dummy, :foo)

          expect(@dummy.foo).to eq('foo')
        end
      end
    end

    describe 'with metrics disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(false)
      end

      it 'does not instrument the method' do
        described_class.instrument_method(@dummy, :foo)

        target = @dummy.singleton_class

        expect(described_class.instrumented?(target)).to eq(false)
      end
    end
  end

  describe '.instrument_instance_method' do
    describe 'with metrics enabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)

        described_class
          .instrument_instance_method(@dummy, :bar)
      end

      it 'instruments instances of the Class' do
        expect(described_class.instrumented?(@dummy)).to eq(true)
      end

      it 'defines a proxy method' do
        mod = described_class.proxy_module(@dummy)

        expect(mod.method_defined?(:bar)).to eq(true)
      end

      it 'calls the instrumented method with the correct arguments' do
        expect(@dummy.new.bar).to eq('bar')
      end

      it 'tracks the call duration upon calling the method' do
        allow(Gitlab::Metrics).to receive(:method_call_threshold)
          .and_return(0)

        allow(described_class).to receive(:transaction)
          .and_return(transaction)

        expect_any_instance_of(Gitlab::Metrics::MethodCall).to receive(:measure)

        @dummy.new.bar
      end

      it 'does not track method calls below a given duration threshold' do
        allow(Gitlab::Metrics).to receive(:method_call_threshold)
          .and_return(100)

        expect(transaction).not_to receive(:add_metric)

        @dummy.new.bar
      end
    end

    describe 'with metrics disabled' do
      before do
        allow(Gitlab::Metrics).to receive(:enabled?).and_return(false)
      end

      it 'does not instrument the method' do
        described_class
          .instrument_instance_method(@dummy, :bar)

        expect(described_class.instrumented?(@dummy)).to eq(false)
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

      expect(described_class.instrumented?(@child1.singleton_class)).to eq(true)
      expect(described_class.instrumented?(@child2.singleton_class)).to eq(true)

      expect(described_class.instrumented?(@child1)).to eq(true)
      expect(described_class.instrumented?(@child2)).to eq(true)
    end

    it 'does not instrument the root module' do
      described_class.instrument_class_hierarchy(@dummy)

      expect(described_class.instrumented?(@dummy)).to eq(false)
    end
  end

  describe '.instrument_methods' do
    before do
      allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)
    end

    it 'instruments all public class methods' do
      described_class.instrument_methods(@dummy)

      expect(described_class.instrumented?(@dummy.singleton_class)).to eq(true)
      expect(@dummy.method(:foo).source_location.first).to match(/instrumentation\.rb/)
    end

    it 'instruments all protected class methods' do
      described_class.instrument_methods(@dummy)

      expect(described_class.instrumented?(@dummy.singleton_class)).to eq(true)
      expect(@dummy.method(:flaky).source_location.first).to match(/instrumentation\.rb/)
    end

    it 'instruments all private instance methods' do
      described_class.instrument_methods(@dummy)

      expect(described_class.instrumented?(@dummy.singleton_class)).to eq(true)
      expect(@dummy.method(:buzz).source_location.first).to match(/instrumentation\.rb/)
    end

    it 'only instruments methods directly defined in the module' do
      mod = Module.new do
        def kittens
        end
      end

      @dummy.extend(mod)

      described_class.instrument_methods(@dummy)

      expect(@dummy).not_to respond_to(:_original_kittens)
    end

    it 'can take a block to determine if a method should be instrumented' do
      described_class.instrument_methods(@dummy) do
        false
      end

      expect(@dummy).not_to respond_to(:_original_foo)
    end
  end

  describe '.instrument_instance_methods' do
    before do
      allow(Gitlab::Metrics).to receive(:enabled?).and_return(true)
    end

    it 'instruments all public instance methods' do
      described_class.instrument_instance_methods(@dummy)

      expect(described_class.instrumented?(@dummy)).to eq(true)
      expect(@dummy.new.method(:bar).source_location.first).to match(/instrumentation\.rb/)
    end

    it 'instruments all protected instance methods' do
      described_class.instrument_instance_methods(@dummy)

      expect(described_class.instrumented?(@dummy)).to eq(true)
      expect(@dummy.new.method(:chaf).source_location.first).to match(/instrumentation\.rb/)
    end

    it 'instruments all private instance methods' do
      described_class.instrument_instance_methods(@dummy)

      expect(described_class.instrumented?(@dummy)).to eq(true)
      expect(@dummy.new.method(:wadus).source_location.first).to match(/instrumentation\.rb/)
    end

    it 'only instruments methods directly defined in the module' do
      mod = Module.new do
        def kittens
        end
      end

      @dummy.include(mod)

      described_class.instrument_instance_methods(@dummy)

      expect(@dummy.new.method(:kittens).source_location.first).not_to match(/instrumentation\.rb/)
    end

    it 'can take a block to determine if a method should be instrumented' do
      described_class.instrument_instance_methods(@dummy) do
        false
      end

      expect(@dummy.new.method(:bar).source_location.first).not_to match(/instrumentation\.rb/)
    end
  end
end
