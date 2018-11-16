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
  end
end
