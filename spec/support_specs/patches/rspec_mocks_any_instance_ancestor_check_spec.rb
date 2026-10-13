# frozen_string_literal: true

require 'fast_spec_helper'

require File.expand_path('../../support/patches/rspec_mocks_any_instance_ancestor_check.rb', __dir__)

# rubocop:disable RSpec/AnyInstanceOf -- the patch under test is for any_instance stubs
RSpec.describe 'rspec-mocks any_instance ancestor check patch', feature_category: :tooling do
  let(:mixin) do
    Module.new do
      def greet
        'mixin'
      end
    end
  end

  let(:parent) do
    mod = mixin

    Class.new do
      include mod

      def name
        'parent'
      end
    end
  end

  let(:child) { Class.new(parent) }

  def recorder_for(klass)
    RSpec::Mocks.space.any_instance_recorder_for(klass, true)
  end

  it 'does not create recorders for ancestors that are not stubbed' do
    allow_any_instance_of(child).to receive(:name).and_return('stubbed')

    expect(child.new.name).to eq('stubbed')
    expect(recorder_for(parent)).to be_nil
    expect(recorder_for(mixin)).to be_nil
    expect(recorder_for(Object)).to be_nil
  end

  # The two examples below pin rspec-mocks' own behaviour, which the patch
  # must not change: stubbing a subclass takes over a method its superclass
  # stubs, while stubbing the superclass afterwards leaves the subclass alone.
  it 'moves the stub to the subclass when the superclass was stubbed first' do
    allow_any_instance_of(parent).to receive(:name).and_return('stubbed parent')
    allow_any_instance_of(child).to receive(:name).and_return('stubbed child')

    expect(parent.new.name).to eq('parent')
    expect(child.new.name).to eq('stubbed child')
  end

  it 'keeps the subclass stub when the superclass is stubbed afterwards' do
    allow_any_instance_of(child).to receive(:name).and_return('stubbed child')
    allow_any_instance_of(parent).to receive(:name).and_return('stubbed parent')

    expect(parent.new.name).to eq('stubbed parent')
    expect(child.new.name).to eq('stubbed child')
  end

  it 'restores the original methods when the example ends' do
    RSpec::Mocks.with_temporary_scope do
      allow_any_instance_of(parent).to receive(:name).and_return('stubbed parent')
      allow_any_instance_of(child).to receive(:greet).and_return('stubbed greet')
    end

    expect(child.new.name).to eq('parent')
    expect(child.new.greet).to eq('mixin')
  end

  it 'still verifies expectations on a subclass' do
    expect_any_instance_of(child).to receive(:name).and_return('expected')

    expect(child.new.name).to eq('expected')
  end
end
# rubocop:enable RSpec/AnyInstanceOf
