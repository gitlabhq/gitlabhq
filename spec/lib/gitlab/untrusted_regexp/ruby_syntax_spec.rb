require 'fast_spec_helper'
require 'support/shared_examples/malicious_regexp_shared_examples'

describe Gitlab::UntrustedRegexp::RubySyntax do
  describe '.matches_syntax?' do
    it 'returns true if regexp is valid' do
      expect(described_class.matches_syntax?('/some .* thing/'))
        .to be true
    end

    it 'returns true if regexp is invalid, but resembles regexp' do
      expect(described_class.matches_syntax?('/some ( thing/'))
        .to be true
    end
  end

  describe '.valid?' do
    it 'returns true if regexp is valid' do
      expect(described_class.valid?('/some .* thing/'))
        .to be true
    end

    it 'returns false if regexp is invalid' do
      expect(described_class.valid?('/some ( thing/'))
        .to be false
    end
  end

  describe '.fabricate' do
    context 'when regexp is valid' do
      it 'fabricates regexp without flags' do
        expect(described_class.fabricate('/some .* thing/')).not_to be_nil
      end
    end

    context 'when regexp is a raw pattern' do
      it 'returns error' do
        expect(described_class.fabricate('some .* thing')).to be_nil
      end
    end
  end

  describe '.fabricate!' do
    context 'when regexp is using /regexp/ scheme with flags' do
      it 'fabricates regexp with a single flag' do
        regexp = described_class.fabricate!('/something/i')

        expect(regexp).to eq Gitlab::UntrustedRegexp.new('(?i)something')
        expect(regexp.scan('SOMETHING')).to be_one
      end

      it 'fabricates regexp with multiple flags' do
        regexp = described_class.fabricate!('/something/im')

        expect(regexp).to eq Gitlab::UntrustedRegexp.new('(?im)something')
      end

      it 'fabricates regexp without flags' do
        regexp = described_class.fabricate!('/something/')

        expect(regexp).to eq Gitlab::UntrustedRegexp.new('something')
      end
    end

    context 'when regexp is a raw pattern' do
      it 'raises an error' do
        expect { described_class.fabricate!('some .* thing') }
          .to raise_error(RegexpError)
      end
    end
  end
end
