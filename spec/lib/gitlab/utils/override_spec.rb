# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Utils::Override do
  let(:base) do
    Struct.new(:good) do
      def self.good
        0
      end
    end
  end

  let(:derived) { Class.new(base).tap { |m| m.extend described_class } }
  let(:extension) { Module.new.tap { |m| m.extend described_class } }

  let(:prepending_class) { base.tap { |m| m.prepend extension } }
  let(:including_class) { base.tap { |m| m.include extension } }

  let(:prepending_class_methods) do
    base.tap { |m| m.singleton_class.prepend extension }
  end

  let(:extending_class_methods) do
    base.tap { |m| m.extend extension }
  end

  let(:klass) { subject }

  def good(mod, bad_arity: false, negative_arity: false)
    mod.module_eval do
      override :good

      if bad_arity
        def good(num)
        end
      elsif negative_arity
        def good(*args)
          super.succ
        end
      else
        def good
          super.succ
        end
      end
    end

    mod
  end

  def bad(mod)
    mod.module_eval do
      override :bad
      def bad
        true
      end
    end

    mod
  end

  shared_examples 'checking as intended' do
    it 'checks ok for overriding method' do
      good(subject)
      result = instance.good

      expect(result).to eq(1)
      described_class.verify!
    end

    it 'checks ok for overriding method using negative arity' do
      good(subject, negative_arity: true)
      result = instance.good

      expect(result).to eq(1)
      described_class.verify!
    end

    it 'raises NotImplementedError when it is not overriding anything' do
      expect do
        bad(subject)
        instance.bad
        described_class.verify!
      end.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError when overriding a method with different arity' do
      expect do
        good(subject, bad_arity: true)
        instance.good(1)
        described_class.verify!
      end.to raise_error(NotImplementedError)
    end
  end

  shared_examples 'checking as intended, nothing was overridden' do
    it 'raises NotImplementedError because it is not overriding it' do
      expect do
        good(subject)
        instance.good
        described_class.verify!
      end.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError when it is not overriding anything' do
      expect do
        bad(subject)
        instance.bad
        described_class.verify!
      end.to raise_error(NotImplementedError)
    end
  end

  shared_examples 'nothing happened' do
    it 'does not complain when it is overriding something' do
      good(subject)
      result = instance.good

      expect(result).to eq(1)
      described_class.verify!
    end

    it 'does not complain when it is not overriding anything' do
      bad(subject)
      result = instance.bad

      expect(result).to eq(true)
      described_class.verify!
    end
  end

  before do
    # Make sure we're not touching the internal cache
    allow(described_class).to receive(:extensions).and_return({})
  end

  describe '#override' do
    context 'when instance is klass.new(0)' do
      let(:instance) { klass.new(0) }

      context 'when STATIC_VERIFICATION is set' do
        before do
          stub_env('STATIC_VERIFICATION', 'true')
        end

        context 'when subject is a class' do
          subject { derived }

          it_behaves_like 'checking as intended'
        end

        context 'when subject is a module, and class is prepending it' do
          subject { extension }
          let(:klass) { prepending_class }

          it_behaves_like 'checking as intended'
        end

        context 'when subject is a module, and class is including it' do
          subject { extension }
          let(:klass) { including_class }

          it_behaves_like 'checking as intended, nothing was overridden'
        end
      end

      context 'when STATIC_VERIFICATION is not set' do
        before do
          stub_env('STATIC_VERIFICATION', nil)
        end

        context 'when subject is a class' do
          subject { derived }

          it_behaves_like 'nothing happened'
        end

        context 'when subject is a module, and class is prepending it' do
          subject { extension }
          let(:klass) { prepending_class }

          it_behaves_like 'nothing happened'
        end

        context 'when subject is a module, and class is including it' do
          subject { extension }
          let(:klass) { including_class }

          it 'does not complain when it is overriding something' do
            good(subject)
            result = instance.good

            expect(result).to eq(0)
            described_class.verify!
          end

          it 'does not complain when it is not overriding anything' do
            bad(subject)
            result = instance.bad

            expect(result).to eq(true)
            described_class.verify!
          end
        end
      end
    end

    context 'when instance is klass' do
      let(:instance) { klass }

      context 'when STATIC_VERIFICATION is set' do
        before do
          stub_env('STATIC_VERIFICATION', 'true')
        end

        context 'when subject is a module, and class is prepending it' do
          subject { extension }
          let(:klass) { prepending_class_methods }

          it_behaves_like 'checking as intended'
        end

        context 'when subject is a module, and class is extending it' do
          subject { extension }
          let(:klass) { extending_class_methods }

          it_behaves_like 'checking as intended, nothing was overridden'
        end
      end
    end
  end
end
