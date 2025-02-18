# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::DelegatorOverride::Validator do
  let(:delegator_class) do
    Class.new(::SimpleDelegator) do
      extend(::Gitlab::Utils::DelegatorOverride)

      def foo; end
    end.prepend(ee_delegator_extension)
  end

  let(:ee_delegator_extension) do
    Module.new do
      extend(::Gitlab::Utils::DelegatorOverride)

      def bar; end
    end
  end

  let(:target_class) do
    Class.new do
      def foo; end

      def bar; end
    end
  end

  let(:validator) { described_class.new(delegator_class) }

  describe '#add_allowlist' do
    it 'adds a method name to the allowlist' do
      validator.add_allowlist([:foo])

      expect(validator.allowed_method_names).to contain_exactly(:foo)
    end
  end

  describe '#add_target' do
    it 'adds the target class' do
      validator.add_target(target_class)

      expect(validator.target_classes).to contain_exactly(target_class)
    end

    it 'adds all descendants of the target' do
      child_class1 = Class.new(target_class)
      child_class2 = Class.new(target_class)
      grandchild_class = Class.new(child_class2)
      validator.add_target(target_class)

      expect(validator.target_classes).to contain_exactly(target_class, child_class1, child_class2, grandchild_class)
    end
  end

  describe '#expand_on_ancestors' do
    it 'adds the allowlist in the ancestors' do
      ancestor_validator = described_class.new(ee_delegator_extension)
      ancestor_validator.add_allowlist([:bar])
      validator.expand_on_ancestors({ ee_delegator_extension => ancestor_validator })

      expect(validator.allowed_method_names).to contain_exactly(:bar)
    end
  end

  describe '#validate_overrides!' do
    before do
      validator.add_target(target_class)
    end

    it 'does not raise an error when the overrides are allowed' do
      validator.add_allowlist([:foo])
      ancestor_validator = described_class.new(ee_delegator_extension)
      ancestor_validator.add_allowlist([:bar])
      validator.expand_on_ancestors({ ee_delegator_extension => ancestor_validator })

      expect { validator.validate_overrides! }.not_to raise_error
    end

    it 'raises an error when there is an override' do
      expect { validator.validate_overrides! }
        .to raise_error(described_class::UnexpectedDelegatorOverrideError)
    end
  end
end
