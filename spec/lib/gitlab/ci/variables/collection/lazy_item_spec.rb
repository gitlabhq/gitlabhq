# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Variables::Collection::LazyItem, feature_category: :pipeline_composition do
  let(:key) { 'LAZY_VAR' }
  let(:value_proc) { -> { 'resolved_value' } }
  let(:lazy_item) { described_class.new(key: key, value_proc: value_proc) }

  describe '#key' do
    it 'returns the key' do
      expect(lazy_item.key).to eq('LAZY_VAR')
    end
  end

  describe '#value' do
    it 'calls the proc and returns the value' do
      expect(lazy_item.value).to eq('resolved_value')
    end

    it 'memoizes the result' do
      call_count = 0
      item = described_class.new(key: key, value_proc: -> {
        call_count += 1
        'value'
      })

      2.times { item.value }

      expect(call_count).to eq(1)
    end

    context 'when proc returns nil' do
      let(:value_proc) { -> { nil } }

      it 'returns nil' do
        expect(lazy_item.value).to be_nil
      end
    end
  end

  describe '#[]' do
    it 'returns key for :key' do
      expect(lazy_item[:key]).to eq('LAZY_VAR')
    end

    it 'returns value for :value' do
      expect(lazy_item[:value]).to eq('resolved_value')
    end

    context 'when value resolves to nil' do
      let(:value_proc) { -> { nil } }

      it 'returns nil for :value' do
        expect(lazy_item[:value]).to be_nil
      end
    end
  end

  describe '#depends_on' do
    it 'returns nil' do
      expect(lazy_item.depends_on).to be_nil
    end
  end

  describe '#raw?' do
    it 'returns false by default' do
      expect(lazy_item.raw?).to be false
    end

    context 'with raw: true' do
      let(:lazy_item) { described_class.new(key: key, value_proc: value_proc, raw: true) }

      it 'returns true' do
        expect(lazy_item.raw?).to be true
      end
    end
  end

  describe '#file?' do
    it 'returns false by default' do
      expect(lazy_item.file?).to be false
    end

    context 'with file: true' do
      let(:lazy_item) { described_class.new(key: key, value_proc: value_proc, file: true) }

      it 'returns true' do
        expect(lazy_item.file?).to be true
      end
    end
  end

  describe '#masked?' do
    it 'returns false by default' do
      expect(lazy_item.masked?).to be false
    end

    context 'with masked: true' do
      let(:lazy_item) { described_class.new(key: key, value_proc: value_proc, masked: true) }

      it 'returns true' do
        expect(lazy_item.masked?).to be true
      end
    end
  end

  describe '#to_runner_variable' do
    it 'returns the runner variable hash' do
      expect(lazy_item.to_runner_variable).to include(
        key: 'LAZY_VAR',
        value: 'resolved_value',
        public: true
      )
    end

    context 'when value resolves to nil' do
      let(:value_proc) { -> { nil } }

      it 'returns nil' do
        expect(lazy_item.to_runner_variable).to be_nil
      end
    end
  end

  describe '#to_hash_variable' do
    it 'returns the hash variable' do
      expect(lazy_item.to_hash_variable).to eq(
        key: 'LAZY_VAR',
        value: 'resolved_value',
        public: true,
        file: false,
        masked: false,
        raw: false
      )
    end

    context 'when value resolves to nil' do
      let(:value_proc) { -> { nil } }

      it 'returns nil' do
        expect(lazy_item.to_hash_variable).to be_nil
      end
    end
  end

  describe '#to_s' do
    it 'returns a string representation' do
      expect(lazy_item.to_s).to eq('LazyItem(LAZY_VAR)')
    end
  end
end
