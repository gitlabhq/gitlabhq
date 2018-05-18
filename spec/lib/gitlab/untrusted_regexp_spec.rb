require 'fast_spec_helper'
require 'support/shared_examples/malicious_regexp_shared_examples'

describe Gitlab::UntrustedRegexp do
  describe '.valid?' do
    it 'returns true if regexp is valid' do
      expect(described_class.valid?('/some ( thing/'))
        .to be false
    end

    it 'returns true if regexp is invalid' do
      expect(described_class.valid?('/some .* thing/'))
        .to be true
    end
  end

  describe '.fabricate' do
    context 'when regexp is using /regexp/ scheme with flags' do
      it 'fabricates regexp with a single flag' do
        regexp = described_class.fabricate('/something/i')

        expect(regexp).to eq described_class.new('(?i)something')
        expect(regexp.scan('SOMETHING')).to be_one
      end

      it 'fabricates regexp with multiple flags' do
        regexp = described_class.fabricate('/something/im')

        expect(regexp).to eq described_class.new('(?im)something')
      end

      it 'fabricates regexp without flags' do
        regexp = described_class.fabricate('/something/')

        expect(regexp).to eq described_class.new('something')
      end
    end

    context 'when regexp is a raw pattern' do
      it 'raises an error' do
        expect { described_class.fabricate('some .* thing') }
          .to raise_error(RegexpError)
      end
    end
  end

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

    it 'can handle regular expressions in multiline mode' do
      regexp = described_class.new('^\d', multiline: true)

      result = regexp === "Header\n\n1. Content"

      expect(result).to be_truthy
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
