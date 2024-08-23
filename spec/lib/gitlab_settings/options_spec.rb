# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSettings::Options, :aggregate_failures, feature_category: :shared do
  let(:config) { { foo: { bar: 'baz' } } }

  subject(:options) { described_class.build(config) }

  shared_examples 'do not mutate' do |method|
    context 'when in production env' do
      it 'returns the unchanged internal hash' do
        stub_rails_env('production')

        expect(Gitlab::AppJsonLogger)
          .to receive(:warn)
          .with(hash_including(
            message: "Warning: Do not mutate GitlabSettings::Options objects: `#{method}`",
            method: method))
          .and_call_original

        expect(options.send(method)).to be_truthy
      end
    end

    context 'when not in production env' do
      it 'raises an exception to avoid changing the internal keys' do
        exception = "Warning: Do not mutate GitlabSettings::Options objects: `#{method}`"

        stub_rails_env('development')
        expect { options.send(method) }.to raise_error(exception)

        stub_rails_env('test')
        expect { options.send(method) }.to raise_error(exception)
      end
    end
  end

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

  describe '#default' do
    it 'returns the option value' do
      expect(options.default).to be_nil

      options['default'] = 'The default value'

      expect(options.default).to eq('The default value')
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

  describe '#dup' do
    it 'returns a deep copy' do
      new_options = options.dup
      expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
      expect(new_options.to_hash).to eq(options.to_hash)

      new_options['test'] = 1
      new_options['foo']['bar'] = 'zzz'

      expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
      expect(new_options.to_hash).to eq('test' => 1, 'foo' => { 'bar' => 'zzz' })
    end
  end

  describe '#merge' do
    it 'returns a new object with the options merged' do
      expect(options.merge(more: 'configs').to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'returns a new object with the duplicated options replaced' do
        expect(options.merge(foo: 'configs').to_hash).to eq('foo' => 'configs')
      end
    end
  end

  describe '#merge!' do
    it 'merges in place with the existing options' do
      options.merge!(more: 'configs') # rubocop: disable Performance/RedundantMerge

      expect(options.to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges in place with the duplicated options replaced' do
        options.merge!(foo: 'configs') # rubocop: disable Performance/RedundantMerge

        expect(options.to_hash).to eq('foo' => 'configs')
      end
    end
  end

  describe '#reverse_merge!' do
    it 'merges in place with the existing options' do
      options.reverse_merge!(more: 'configs')

      expect(options.to_hash).to eq(
        'foo' => { 'bar' => 'baz' },
        'more' => 'configs'
      )
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges in place with the duplicated options not replaced' do
        options.reverse_merge!(foo: 'configs')

        expect(options.to_hash).to eq('foo' => { 'bar' => 'baz' })
      end
    end
  end

  describe '#deep_merge' do
    it 'returns a new object with the options merged' do
      expect(options.deep_merge(foo: { more: 'configs' }).to_hash).to eq('foo' => {
        'bar' => 'baz',
        'more' => 'configs'
      })
    end

    context 'when the merge hash replaces existing configs' do
      it 'returns a new object with the duplicated options replaced' do
        expect(options.deep_merge(foo: { bar: 'configs' }).to_hash).to eq('foo' => {
          'bar' => 'configs'
        })
      end
    end
  end

  describe '#deep_merge!' do
    it 'merges in place with the existing options' do
      expect(options.deep_merge(foo: { more: 'configs' }).to_hash).to eq('foo' => {
        'bar' => 'baz',
        'more' => 'configs'
      })
    end

    context 'when the merge hash replaces existing configs' do
      it 'merges in place with the duplicated options replaced' do
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

  describe '#symbolize_keys!' do
    it_behaves_like 'do not mutate', :symbolize_keys!
  end

  describe '#stringify_keys!' do
    it_behaves_like 'do not mutate', :stringify_keys!
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
      context 'when in production env' do
        it 'delegates the method to the internal options hash' do
          stub_rails_env('production')

          expect(Gitlab::AppJsonLogger)
            .to receive(:warn)
            .with(hash_including(
              message: 'Calling a hash method on GitlabSettings::Options: `delete`',
              method: :delete))
            .and_call_original

          expect { options.foo.delete('bar') }
            .to change { options.to_hash }
            .to({ 'foo' => {} })
        end
      end

      context 'when not in production env' do
        it 'delegates the method to the internal options hash' do
          exception = 'Calling a hash method on GitlabSettings::Options: `delete`'

          stub_rails_env('development')
          expect { options.foo.delete('bar') }.to raise_error(exception)

          stub_rails_env('test')
          expect { options.foo.delete('bar') }.to raise_error(exception)
        end
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
