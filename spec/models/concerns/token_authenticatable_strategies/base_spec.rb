# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::Base, feature_category: :system_access do
  let(:instance) { double(:instance) }
  let(:field) { double(:field) }

  describe '#token_fields' do
    let(:strategy) { described_class.new(instance, field, options) }
    let(:field) { 'some_token' }
    let(:options) { {} }

    it 'includes the token field' do
      expect(strategy.token_fields).to contain_exactly(field)
    end

    context 'with expires_at option' do
      let(:options) { { expires_at: true } }

      it 'includes the token_expires_at field' do
        expect(strategy.token_fields).to contain_exactly(field, 'some_token_expires_at')
      end
    end
  end

  describe '#format_token' do
    let(:strategy) { described_class.new(instance, field, options) }

    let(:instance) { build(:ci_build, name: 'build_name_for_format_option', partition_id: partition_id) }
    let(:partition_id) { 100 }
    let(:field) { 'token' }
    let(:options) { {} }

    let(:token) { 'a_secret_token' }

    it 'returns the origin token' do
      expect(strategy.format_token(instance, token)).to eq(token)
    end

    context 'when format_with_prefix option is provided' do
      context 'with symbol' do
        let(:options) { { format_with_prefix: :partition_id_prefix_in_16_bit_encode } }
        let(:partition_id_in_16_bit_encode_with_underscore) { "#{partition_id.to_s(16)}_" }
        let(:formatted_token) { "#{partition_id_in_16_bit_encode_with_underscore}#{token}" }

        it 'returns a formatted token from the format_with_prefix option' do
          expect(strategy.format_token(instance, token)).to eq(formatted_token)
        end
      end

      context 'with something else' do
        let(:options) { { format_with_prefix: false } }

        it 'raise not implemented' do
          expect { strategy.format_token(instance, token) }.to raise_error(NotImplementedError)
        end
      end
    end
  end

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
