# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::Base do
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
        strategy = described_class.fabricate(instance, field, encrypted: :required)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Encrypted
      end
    end

    context 'when no strategy is specified' do
      it 'fabricates insecure strategy object' do
        strategy = described_class.fabricate(instance, field, something: :required)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Insecure
      end
    end

    context 'when incompatible options are provided' do
      it 'raises an error' do
        expect { described_class.fabricate(instance, field, digest: true, encrypted: :required) }
          .to raise_error ArgumentError
      end
    end
  end
end
