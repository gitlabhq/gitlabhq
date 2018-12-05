require 'spec_helper'

describe TokenAuthenticatableStrategies::Base do
  let(:instance) { double(:instance) }
  let(:field) { double(:field) }

  describe '.fabricate' do
    context 'when digest stragegy is specified' do
      it 'fabricates digest strategy object' do
        strategy = described_class.fabricate(instance, field, digest: true)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Digest
      end
    end

    context 'when encrypted strategy is specified' do
      it 'fabricates encrypted strategy object' do
        strategy = described_class.fabricate(instance, field, encrypted: true)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Encrypted
      end
    end

    context 'when no strategy is specified' do
      it 'fabricates insecure strategy object' do
        strategy = described_class.fabricate(instance, field, something: true)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Insecure
      end
    end

    context 'when incompatible options are provided' do
      it 'raises an error' do
        expect { described_class.fabricate(instance, field, digest: true, encrypted: true) }
          .to raise_error ArgumentError
      end
    end
  end

  describe '#fallback?' do
    context 'when fallback is set' do
      it 'recognizes fallback setting' do
        strategy = described_class.new(instance, field, fallback: true)

        expect(strategy.fallback?).to be true
      end
    end

    context 'when fallback is not a valid value' do
      it 'raises an error' do
        strategy = described_class.new(instance, field, fallback: 'something')

        expect { strategy.fallback? }.to raise_error ArgumentError
      end
    end

    context 'when fallback is not set' do
      it 'raises an error' do
        strategy = described_class.new(instance, field, {})

        expect(strategy.fallback?).to eq false
      end
    end
  end
end
