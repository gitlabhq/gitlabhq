# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Variables::Collection::LazyHash, feature_category: :pipeline_composition do
  let(:collection) do
    Gitlab::Ci::Variables::Collection.new([
      { key: 'VAR1', value: 'value1' },
      { key: 'VAR2', value: 'value2' }
    ])
  end

  let(:lazy_hash) { described_class.new(collection) }

  describe '#[]' do
    it 'returns the item from the collection' do
      item = lazy_hash['VAR1']

      expect(item).to be_a(Gitlab::Ci::Variables::Collection::Item)
      expect(item.key).to eq('VAR1')
      expect(item.value).to eq('value1')
    end

    it 'returns nil for missing keys' do
      expect(lazy_hash['MISSING']).to be_nil
    end
  end

  describe '#fetch' do
    it 'returns the value for existing keys' do
      expect(lazy_hash.fetch('VAR1')).to eq('value1')
    end

    it 'returns default for missing keys' do
      expect(lazy_hash.fetch('MISSING', 'default')).to eq('default')
    end

    it 'returns nil for missing keys without default' do
      expect(lazy_hash.fetch('MISSING')).to be_nil
    end
  end

  describe '#with_indifferent_access' do
    it 'returns self' do
      expect(lazy_hash.with_indifferent_access).to be(lazy_hash)
    end
  end

  describe '#key?' do
    it 'raises NotImplementedError to prevent checking keys' do
      expect { lazy_hash.key?('VAR1') }.to raise_error(
        NotImplementedError,
        "LazyHash does not support key? - use fetch(key, nil) to check if a variable is present"
      )
    end
  end

  describe '#has_key?' do
    it 'is an alias for key? and raises NotImplementedError' do
      expect { lazy_hash.has_key?('VAR1') }.to raise_error(NotImplementedError)
    end
  end

  describe '#to_hash' do
    it 'raises NotImplementedError to prevent evaluating all lazy variables' do
      expect { lazy_hash.to_hash }.to raise_error(
        NotImplementedError,
        "LazyHash#to_hash would evaluate all lazy variables. Use [] or fetch to access individual variables."
      )
    end
  end

  describe '#to_h' do
    it 'is an alias for to_hash and raises NotImplementedError' do
      expect { lazy_hash.to_h }.to raise_error(NotImplementedError)
    end
  end

  context 'with lazy items' do
    let(:collection) do
      Gitlab::Ci::Variables::Collection.new.tap do |c|
        c.append(key: 'REGULAR', value: 'regular_value')
        c.append(key: 'LAZY', lazy: true, value: -> { 'lazy_value' })
        c.append(key: 'LAZY_NIL', lazy: true, value: -> { nil })
      end
    end

    describe '#[]' do
      it 'returns lazy items without resolving them' do
        item = lazy_hash['LAZY']

        expect(item).to be_a(Gitlab::Ci::Variables::Collection::LazyItem)
      end

      it 'resolves lazy items when accessing value' do
        item = lazy_hash['LAZY']

        expect(item.value).to eq('lazy_value')
      end
    end

    describe '#fetch' do
      it 'resolves lazy items and returns the value' do
        expect(lazy_hash.fetch('LAZY')).to eq('lazy_value')
      end

      it 'returns nil for lazy items that resolve to nil' do
        expect(lazy_hash.fetch('LAZY_NIL')).to be_nil
      end
    end
  end
end
