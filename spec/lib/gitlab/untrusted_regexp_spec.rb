require 'spec_helper'

describe Gitlab::UntrustedRegexp do
  describe '#initialize' do
    subject { described_class.new(pattern) }

    context 'invalid regexp' do
      let(:pattern) { '[' }

      it { expect { subject }.to raise_error(RegexpError) }
    end
  end

  describe '#replace_all' do
    it 'replaces all instances of the match in a string' do
      result = described_class.new('foo').replace_all('foo bar foo', 'oof')

      expect(result).to eq('oof bar oof')
    end
  end

  describe '#replace' do
    it 'replaces the first instance of the match in a string' do
      result = described_class.new('foo').replace('foo bar foo', 'oof')

      expect(result).to eq('oof bar foo')
    end
  end

  describe '#===' do
    it 'returns true for a match' do
      result = described_class.new('foo') === 'a foo here'

      expect(result).to be_truthy
    end

    it 'returns false for no match' do
      result = described_class.new('foo') === 'a bar here'

      expect(result).to be_falsy
    end
  end

  describe '#scan' do
    subject { described_class.new(regexp).scan(text) }
    context 'malicious regexp' do
      let(:text) { malicious_text }
      let(:regexp) { malicious_regexp }

      include_examples 'malicious regexp'
    end

    context 'empty regexp' do
      let(:regexp) { '' }
      let(:text) { 'foo' }

      it 'returns an array of nil matches' do
        is_expected.to eq([nil, nil, nil, nil])
      end
    end

    context 'empty capture group regexp' do
      let(:regexp) { '()' }
      let(:text) { 'foo' }

      it 'returns an array of nil matches in an array' do
        is_expected.to eq([[nil], [nil], [nil], [nil]])
      end
    end

    context 'no capture group' do
      let(:regexp) { '.+' }
      let(:text) { 'foo' }

      it 'returns the whole match' do
        is_expected.to eq(['foo'])
      end
    end

    context 'one capture group' do
      let(:regexp) { '(f).+' }
      let(:text) { 'foo' }

      it 'returns the captured part' do
        is_expected.to eq([%w[f]])
      end
    end

    context 'two capture groups' do
      let(:regexp) { '(f).(o)' }
      let(:text) { 'foo' }

      it 'returns the captured parts' do
        is_expected.to eq([%w[f o]])
      end
    end
  end
end
