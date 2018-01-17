require 'spec_helper'

describe Gitlab::Utils::Override do
  let(:base) { Struct.new(:good) }

  let(:derived) { Class.new(base).tap { |m| m.extend described_class } }
  let(:extension) { Module.new.tap { |m| m.extend described_class } }

  let(:prepending_class) { base.tap { |m| m.prepend extension } }
  let(:including_class) { base.tap { |m| m.include extension } }

  let(:klass) { subject }

  def good(mod)
    mod.module_eval do
      override :good
      def good
        super.succ
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
      result = klass.new(0).good

      expect(result).to eq(1)
      described_class.verify!
    end

    it 'raises NotImplementedError when it is not overriding anything' do
      expect do
        bad(subject)
        klass.new(0).bad
        described_class.verify!
      end.to raise_error(NotImplementedError)
    end
  end

  shared_examples 'nothing happened' do
    it 'does not complain when it is overriding something' do
      good(subject)
      result = klass.new(0).good

      expect(result).to eq(1)
      described_class.verify!
    end

    it 'does not complain when it is not overriding anything' do
      bad(subject)
      result = klass.new(0).bad

      expect(result).to eq(true)
      described_class.verify!
    end
  end

  before do
    # Make sure we're not touching the internal cache
    allow(described_class).to receive(:extensions).and_return({})
  end

  describe '#override' do
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

        it 'raises NotImplementedError because it is not overriding it' do
          expect do
            good(subject)
            klass.new(0).good
            described_class.verify!
          end.to raise_error(NotImplementedError)
        end

        it 'raises NotImplementedError when it is not overriding anything' do
          expect do
            bad(subject)
            klass.new(0).bad
            described_class.verify!
          end.to raise_error(NotImplementedError)
        end
      end
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
        result = klass.new(0).good

        expect(result).to eq(0)
        described_class.verify!
      end

      it 'does not complain when it is not overriding anything' do
        bad(subject)
        result = klass.new(0).bad

        expect(result).to eq(true)
        described_class.verify!
      end
    end
  end
end
