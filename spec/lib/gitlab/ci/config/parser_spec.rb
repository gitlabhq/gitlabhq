require 'spec_helper'

describe Gitlab::Ci::Config::Parser do
  let(:parser) { described_class.new(yml) }

  context 'when yaml syntax is correct' do
    let(:yml) { 'image: ruby:2.2' }

    describe '#valid?' do
      it 'returns true' do
        expect(parser.valid?).to be true
      end
    end

    describe '#parse' do
      it 'returns a hash' do
        expect(parser.parse).to be_a Hash
      end

      it 'returns a valid hash' do
        expect(parser.parse).to eq(image: 'ruby:2.2')
      end
    end
  end

  context 'when yaml syntax is incorrect' do
    let(:yml) { '// incorrect' }

    describe '#valid?' do
      it 'returns false' do
        expect(parser.valid?).to be false
      end
    end

    describe '#parse' do
      it 'raises error' do
        expect { parser.parse }.to raise_error(
          Gitlab::Ci::Config::Parser::FormatError,
          'Invalid configuration format'
        )
      end
    end
  end

  context 'when yaml config is empty' do
    let(:yml) { '' }

    describe '#valid?' do
      it 'returns false' do
        expect(parser.valid?).to be false
      end
    end
  end
end
