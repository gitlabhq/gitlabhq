require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Attributable do
  let(:node) do
    Class.new do
      include Gitlab::Ci::Config::Entry::Attributable
    end
  end

  let(:instance) { node.new }

  before do
    node.class_eval do
      attributes :name, :test
    end
  end

  context 'when config is a hash' do
    before do
      allow(instance)
        .to receive(:config)
        .and_return({ name: 'some name', test: 'some test' })
    end

    it 'returns the value of config' do
      expect(instance.name).to eq 'some name'
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
      expect(instance.test).to be_nil
    end
  end

  context 'when method is already defined in a superclass' do
    it 'raises an error' do
      expectation = expect do
        Class.new(String) do
          include Gitlab::Ci::Config::Entry::Attributable

          attributes :length
        end
      end

      expectation.to raise_error(ArgumentError, 'Method already defined!')
    end
  end
end
