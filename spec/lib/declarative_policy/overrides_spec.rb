# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'rspec-parameterized'

RSpec.describe 'DeclarativePolicy overrides' do
  let(:foo_policy) do
    Class.new(DeclarativePolicy::Base) do
      condition(:foo_prop_cond) { @subject.foo_prop }

      rule { foo_prop_cond }.policy do
        enable :common_ability
        enable :foo_prop_ability
      end
    end
  end

  let(:bar_policy) do
    Class.new(DeclarativePolicy::Base) do
      delegate { @subject.foo }

      overrides :common_ability

      condition(:bar_prop_cond) { @subject.bar_prop }

      rule { bar_prop_cond }.policy do
        enable :common_ability
        enable :bar_prop_ability
      end

      rule { bar_prop_cond & can?(:foo_prop_ability) }.policy do
        enable :combined_ability
      end
    end
  end

  before do
    stub_const('Foo', Struct.new(:foo_prop))
    stub_const('FooPolicy', foo_policy)
    stub_const('Bar', Struct.new(:foo, :bar_prop))
    stub_const('BarPolicy', bar_policy)
  end

  where(:foo_prop, :bar_prop) do
    [
      [true, true],
      [true, false],
      [false, true],
      [false, false]
    ]
  end

  with_them do
    let(:foo) { Foo.new(foo_prop) }
    let(:bar) { Bar.new(foo, bar_prop) }

    it 'determines the correct bar_prop_ability (non-delegated) permissions for bar' do
      policy = DeclarativePolicy.policy_for(nil, bar)
      expect(policy.allowed?(:bar_prop_ability)).to eq(bar_prop)
    end

    it 'determines the correct foo_prop (non-overridden) permissions for bar' do
      policy = DeclarativePolicy.policy_for(nil, bar)
      expect(policy.allowed?(:foo_prop_ability)).to eq(foo_prop)
    end

    it 'determines the correct common_ability (overridden) permissions for bar' do
      policy = DeclarativePolicy.policy_for(nil, bar)
      expect(policy.allowed?(:common_ability)).to eq(bar_prop)
    end

    it 'determines the correct common_ability permissions for foo' do
      policy = DeclarativePolicy.policy_for(nil, foo)
      expect(policy.allowed?(:common_ability)).to eq(foo_prop)
    end

    it 'allows combinations of overridden and inherited values' do
      policy = DeclarativePolicy.policy_for(nil, bar)
      expect(policy.allowed?(:combined_ability)).to eq(foo_prop && bar_prop)
    end
  end
end
