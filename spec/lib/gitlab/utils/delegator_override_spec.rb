# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::DelegatorOverride do
  let(:delegator_class) do
    Class.new(::SimpleDelegator) do
      extend(::Gitlab::Utils::DelegatorOverride)

      def foo; end
    end
  end

  let(:target_class) do
    Class.new do
      def foo; end

      def bar; end
    end
  end

  let(:dummy_module) do
    Module.new do
      def foobar; end
    end
  end

  before do
    stub_env('STATIC_VERIFICATION', 'true')
    described_class.validators.clear
  end

  describe '.delegator_target' do
    subject { delegator_class.delegator_target(target_class) }

    it 'sets the delegator target to the validator' do
      expect(described_class.validator(delegator_class))
        .to receive(:add_target).with(target_class)

      subject
    end

    context 'when the class does not inherit SimpleDelegator' do
      let(:delegator_class) do
        Class.new do
          extend(::Gitlab::Utils::DelegatorOverride)
        end
      end

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError, /not a subclass of 'SimpleDelegator' class/)
      end
    end
  end

  describe '.delegator_override' do
    subject { delegator_class.delegator_override(:foo) }

    it 'adds the method name to the allowlist' do
      expect(described_class.validator(delegator_class))
        .to receive(:add_allowlist).with([:foo])

      subject
    end
  end

  describe '.delegator_override_with' do
    subject { delegator_class.delegator_override_with(dummy_module) }

    it 'adds the method names of the module to the allowlist' do
      expect(described_class.validator(delegator_class))
        .to receive(:add_allowlist).with([:foobar])

      subject
    end
  end

  describe '.verify!' do
    subject { described_class.verify! }

    it 'does not raise an error when an override is in allowlist' do
      delegator_class.delegator_target(target_class)
      delegator_class.delegator_override(:foo)

      expect { subject }.not_to raise_error
    end

    it 'raises an error when there is an override' do
      delegator_class.delegator_target(target_class)

      expect { subject }.to raise_error(Gitlab::Utils::DelegatorOverride::Validator::UnexpectedDelegatorOverrideError)
    end
  end
end
