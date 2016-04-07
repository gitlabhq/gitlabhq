require 'spec_helper'

describe Gitlab::Metrics do
  describe '.settings' do
    it 'returns a Hash' do
      expect(described_class.settings).to be_an_instance_of(Hash)
    end
  end

  describe '.enabled?' do
    it 'returns a boolean' do
      expect([true, false].include?(described_class.enabled?)).to eq(true)
    end
  end

  describe '.submit_metrics' do
    it 'prepares and writes the metrics to InfluxDB' do
      connection = double(:connection)
      pool       = double(:pool)

      expect(pool).to receive(:with).and_yield(connection)
      expect(connection).to receive(:write_points).with(an_instance_of(Array))
      expect(Gitlab::Metrics).to receive(:pool).and_return(pool)

      described_class.submit_metrics([{ 'series' => 'kittens', 'tags' => {} }])
    end
  end

  describe '.prepare_metrics' do
    it 'returns a Hash with the keys as Symbols' do
      metrics = described_class.
        prepare_metrics([{ 'values' => {}, 'tags' => {} }])

      expect(metrics).to eq([{ values: {}, tags: {} }])
    end

    it 'escapes tag values' do
      metrics = described_class.prepare_metrics([
        { 'values' => {}, 'tags' => { 'foo' => 'bar=' } }
      ])

      expect(metrics).to eq([{ values: {}, tags: { 'foo' => 'bar\\=' } }])
    end

    it 'drops empty tags' do
      metrics = described_class.prepare_metrics([
        { 'values' => {}, 'tags' => { 'cats' => '', 'dogs' => nil } }
      ])

      expect(metrics).to eq([{ values: {}, tags: {} }])
    end
  end

  describe '.escape_value' do
    it 'escapes an equals sign' do
      expect(described_class.escape_value('foo=')).to eq('foo\\=')
    end

    it 'casts values to Strings' do
      expect(described_class.escape_value(10)).to eq('10')
    end
  end

  describe '.measure' do
    context 'without a transaction' do
      it 'returns the return value of the block' do
        val = Gitlab::Metrics.measure(:foo) { 10 }

        expect(val).to eq(10)
      end
    end

    context 'with a transaction' do
      let(:transaction) { Gitlab::Metrics::Transaction.new }

      before do
        allow(Gitlab::Metrics::Transaction).to receive(:current).
          and_return(transaction)
      end

      it 'adds a metric to the current transaction' do
        expect(transaction).to receive(:add_metric).
          with(:foo, { duration: a_kind_of(Numeric) }, { tag: 'value' })

        Gitlab::Metrics.measure(:foo, {}, tag: 'value') { 10 }
      end

      it 'supports adding of custom values' do
        values = { duration: a_kind_of(Numeric), number: 10 }

        expect(transaction).to receive(:add_metric).
          with(:foo, values, { tag: 'value' })

        Gitlab::Metrics.measure(:foo, { number: 10 }, tag: 'value') { 10 }
      end

      it 'returns the return value of the block' do
        val = Gitlab::Metrics.measure(:foo) { 10 }

        expect(val).to eq(10)
      end
    end
  end
end
