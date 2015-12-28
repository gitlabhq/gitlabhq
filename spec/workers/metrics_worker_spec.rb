require 'spec_helper'

describe MetricsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'prepares and writes the metrics to InfluxDB' do
      connection = double(:connection)
      pool       = double(:pool)

      expect(pool).to receive(:with).and_yield(connection)
      expect(connection).to receive(:write_points).with(an_instance_of(Array))
      expect(Gitlab::Metrics).to receive(:pool).and_return(pool)

      worker.perform([{ 'series' => 'kittens', 'tags' => {} }])
    end
  end

  describe '#prepare_metrics' do
    it 'returns a Hash with the keys as Symbols' do
      metrics = worker.prepare_metrics([{ 'values' => {}, 'tags' => {} }])

      expect(metrics).to eq([{ values: {}, tags: {} }])
    end

    it 'escapes tag values' do
      metrics = worker.prepare_metrics([
        { 'values' => {}, 'tags' => { 'foo' => 'bar=' } }
      ])

      expect(metrics).to eq([{ values: {}, tags: { 'foo' => 'bar\\=' } }])
    end

    it 'drops empty tags' do
      metrics = worker.prepare_metrics([
        { 'values' => {}, 'tags' => { 'cats' => '', 'dogs' => nil } }
      ])

      expect(metrics).to eq([{ values: {}, tags: {} }])
    end
  end

  describe '#escape_value' do
    it 'escapes an equals sign' do
      expect(worker.escape_value('foo=')).to eq('foo\\=')
    end

    it 'casts values to Strings' do
      expect(worker.escape_value(10)).to eq('10')
    end
  end
end
