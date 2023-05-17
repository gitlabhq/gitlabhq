# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSettings::Options, :aggregate_failures, feature_category: :shared do
  let(:config) { { foo: { bar: 'baz' } } }

  subject(:options) { described_class.build(config) }

  describe '.build' do
    context 'when argument is a hash' do
      it 'creates a new GitlabSettings::Options instance' do
        options = described_class.build(config)

        expect(options).to be_a described_class
        expect(options.foo).to be_a described_class
        expect(options.foo.bar).to eq 'baz'
      end
    end
  end

  describe '#[]' do
    it 'accesses the configuration key as string' do
      expect(options['foo']).to be_a described_class
      expect(options['foo']['bar']).to eq 'baz'

      expect(options['inexistent']).to be_nil
    end

    it 'accesses the configuration key as symbol' do
      expect(options[:foo]).to be_a described_class
      expect(options[:foo][:bar]).to eq 'baz'

      expect(options[:inexistent]).to be_nil
    end
  end

  describe '#[]=' do
    it 'changes the configuration key as string' do
      options['foo']['bar'] = 'anothervalue'

      expect(options['foo']['bar']).to eq 'anothervalue'
    end

    it 'changes the configuration key as symbol' do
      options[:foo][:bar] = 'anothervalue'

      expect(options[:foo][:bar]).to eq 'anothervalue'
    end

    context 'when key does not exist' do
      it 'creates a new configuration by string key' do
        options['inexistent'] = 'value'

        expect(options['inexistent']).to eq 'value'
      end

      it 'creates a new configuration by string key' do
        options[:inexistent] = 'value'

        expect(options[:inexistent]).to eq 'value'
      end
    end
  end

  describe '#key?' do
    it 'checks if a string key exists' do
      expect(options.key?('foo')).to be true
      expect(options.key?('inexistent')).to be false
    end

    it 'checks if a symbol key exists' do
      expect(options.key?(:foo)).to be true
      expect(options.key?(:inexistent)).to be false
    end
  end

  describe '#to_hash' do
    it 'returns the hash representation of the config' do
      expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
    end
  end

  describe '#merge' do
    it 'merges a hash to the existing options' do
      expect(options.merge(more: 'configs').to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges a hash to the existing options' do
        expect(options.merge(foo: 'configs').to_hash).to eq('foo' => 'configs')
      end
    end
  end

  describe '#deep_merge' do
    it 'merges a hash to the existing options' do
      expect(options.deep_merge(foo: { more: 'configs' }).to_hash).to eq('foo' => {
        'bar' => 'baz',
        'more' => 'configs'
      })
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges a hash to the existing options' do
        expect(options.deep_merge(foo: { bar: 'configs' }).to_hash).to eq('foo' => {
          'bar' => 'configs'
        })
      end
    end
  end

  describe '#is_a?' do
    it 'returns false for anything different of Hash or GitlabSettings::Options' do
      expect(options.is_a?(described_class)).to be true
      expect(options.is_a?(Hash)).to be true
      expect(options.is_a?(String)).to be false
    end
  end

  describe '#method_missing' do
    context 'when method is an option' do
      it 'delegates methods to options keys' do
        expect(options.foo.bar).to eq('baz')
      end

      it 'uses methods to change options values' do
        expect { options.foo = 1 }
          .to change { options.foo }
          .to(1)
      end
    end

    context 'when method is not an option' do
      it 'delegates the method to the internal options hash' do
        expect { options.foo.delete('bar') }
          .to change { options.to_hash }
          .to({ 'foo' => {} })
      end
    end

    context 'when method is not an option and does not exist in hash' do
      it 'raises GitlabSettings::MissingSetting' do
        expect { options.anything }
          .to raise_error(
            ::GitlabSettings::MissingSetting,
            "option 'anything' not defined"
          )
      end
    end
  end
end
