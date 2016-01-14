require 'spec_helper'

describe Gitlab::Metrics::Metric do
  let(:metric) do
    described_class.new('foo', { number: 10 }, { host: 'localtoast' })
  end

  describe '#series' do
    subject { metric.series }

    it { is_expected.to eq('foo') }
  end

  describe '#values' do
    subject { metric.values }

    it { is_expected.to eq({ number: 10 }) }
  end

  describe '#tags' do
    subject { metric.tags }

    it { is_expected.to eq({ host: 'localtoast' }) }
  end

  describe '#to_hash' do
    it 'returns a Hash' do
      expect(metric.to_hash).to be_an_instance_of(Hash)
    end

    describe 'the returned Hash' do
      let(:hash) { metric.to_hash }

      it 'includes the series' do
        expect(hash[:series]).to eq('foo')
      end

      it 'includes the tags' do
        expect(hash[:tags]).to be_an_instance_of(Hash)
      end

      it 'includes the values' do
        expect(hash[:values]).to eq({ number: 10 })
      end

      it 'includes the timestamp' do
        expect(hash[:timestamp]).to be_an_instance_of(Fixnum)
      end
    end
  end
end
