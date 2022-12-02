# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Config::Entry::Attributable do
  let(:node) do
    Class.new do
      include Gitlab::Config::Entry::Attributable
    end
  end

  let(:instance) { node.new }
  let(:prefix) { nil }

  before do
    node.class_exec(prefix) do |pre|
      attributes :name, :test, prefix: pre
    end
  end

  context 'when config is a hash' do
    before do
      allow(instance)
        .to receive(:config)
        .and_return({ name: 'some name', test: 'some test' })
    end

    context 'and is provided a prefix' do
      let(:prefix) { :pre }

      it 'returns the value of config' do
        expect(instance).to have_pre_name
        expect(instance.pre_name).to eq 'some name'
        expect(instance).to have_pre_test
        expect(instance.pre_test).to eq 'some test'
      end
    end

    it 'returns the value of config' do
      expect(instance).to have_name
      expect(instance.name).to eq 'some name'
      expect(instance).to have_test
      expect(instance.test).to eq 'some test'
    end

    it 'returns no method error for unknown attributes' do
      expect { instance.unknown }.to raise_error(NoMethodError)
    end
  end

  context 'when config is not a hash' do
    before do
      allow(instance)
        .to receive(:config)
        .and_return('some test')
    end

    it 'returns nil' do
      expect(instance).not_to have_test
      expect(instance.test).to be_nil
    end
  end

  context 'when method is already defined in a superclass' do
    it 'raises an error' do
      expectation = expect do
        Class.new(String) do
          include Gitlab::Config::Entry::Attributable

          attributes :length
        end
      end

      expectation.to raise_error(ArgumentError, /Method 'length' already defined in/)
    end
  end
end
