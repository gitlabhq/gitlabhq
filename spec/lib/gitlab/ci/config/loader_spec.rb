require 'spec_helper'

describe Gitlab::Ci::Config::Loader do
  let(:loader) { described_class.new(yml) }

  context 'when yaml syntax is correct' do
    let(:yml) { 'image: ruby:2.2' }

    describe '#valid?' do
      it 'returns true' do
        expect(loader.valid?).to be true
      end
    end

    describe '#load!' do
      it 'returns a valid hash' do
        expect(loader.load!).to eq(image: 'ruby:2.2')
      end
    end
  end

  context 'when yaml syntax is incorrect' do
    let(:yml) { '// incorrect' }

    describe '#valid?' do
      it 'returns false' do
        expect(loader.valid?).to be false
      end
    end

    describe '#load!' do
      it 'raises error' do
        expect { loader.load! }.to raise_error(
          Gitlab::Ci::Config::Loader::FormatError,
          'Invalid configuration format'
        )
      end
    end
  end

  context 'when there is an unknown alias' do
    let(:yml) { 'steps: *bad_alias' }

    describe '#initialize' do
      it 'raises FormatError' do
        expect { loader }.to raise_error(Gitlab::Ci::Config::Loader::FormatError, 'Unknown alias: bad_alias')
      end
    end
  end

  context 'when yaml config is empty' do
    let(:yml) { '' }

    describe '#valid?' do
      it 'returns false' do
        expect(loader.valid?).to be false
      end
    end
  end
end
