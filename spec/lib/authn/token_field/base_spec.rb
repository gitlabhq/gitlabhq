# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::Base, feature_category: :system_access do
  include ::TokenAuthenticatableMatchers

  let(:field) { 'token' }
  let(:digest_field) { "#{field}_digest" }
  let(:expires_at_field) { "#{field}_expires_at" }
  let(:options) { { unique: false, format_with_prefix: :token_prefix } }
  let(:test_class) do
    Struct.new(:token_prefix, field, digest_field, expires_at_field) do
      alias_method :read_attribute, :[]
    end
  end

  let(:concrete_strategy) do
    Class.new(described_class) do
      def get_token(token_owner_record)
        token_owner_record[token_field]
      end

      def set_token(token_owner_record, token)
        token_owner_record[token_field] = token if token
      end

      def token_set?(token_owner_record)
        token_owner_record[token_field].present?
      end
    end
  end

  let(:token_owner_record) { test_class.new }

  subject(:strategy) { concrete_strategy.new(test_class, field, options) }

  describe '.fabricate' do
    context 'when digest strategy is specified' do
      it 'fabricates digest strategy object' do
        strategy = described_class.fabricate(test_class, field, digest: true)

        expect(strategy).to be_a Authn::TokenField::Digest
      end
    end

    context 'when encrypted strategy is specified' do
      it 'fabricates encrypted strategy object' do
        strategy = described_class.fabricate(test_class, field, encrypted: :required)

        expect(strategy).to be_a Authn::TokenField::Encrypted
      end
    end

    context 'when no strategy is specified' do
      it 'fabricates insecure strategy object' do
        strategy = described_class.fabricate(test_class, field, something: :required)

        expect(strategy).to be_a Authn::TokenField::Insecure
      end
    end

    context 'when incompatible options are provided' do
      it 'raises an error' do
        expect { described_class.fabricate(test_class, field, digest: true, encrypted: :required) }
          .to raise_error ArgumentError
      end
    end
  end

  describe '#find_token_authenticatable' do
    subject(:strategy) { described_class.new(test_class, field, options) }

    it 'raises a NotImplementedError error' do
      expect { strategy.find_token_authenticatable(token_owner_record) }.to raise_error(NotImplementedError)
    end
  end

  describe '#get_token' do
    subject(:strategy) { described_class.new(test_class, field, options) }

    it 'raises a NotImplementedError error' do
      expect { strategy.get_token(token_owner_record) }.to raise_error(NotImplementedError)
    end
  end

  describe '#set_token' do
    subject(:strategy) { described_class.new(test_class, field, options) }

    it 'raises a NotImplementedError error' do
      expect { strategy.set_token(token_owner_record, 'foo') }.to raise_error(NotImplementedError)
    end
  end

  describe '#token_fields' do
    it 'includes the token field' do
      expect(strategy.token_fields).to contain_exactly(field)
    end

    context 'with expires_at option' do
      let(:options) { { expires_at: true } }

      it 'includes the token_expires_at field' do
        expect(strategy.token_fields).to contain_exactly(field, expires_at_field)
      end
    end
  end

  describe '#sensitive_fields' do
    it 'includes the token field' do
      expect(strategy.sensitive_fields).to contain_exactly(field)
    end

    context 'with expires_at option' do
      let(:options) { { expires_at: true } }

      it 'includes the token_expires_at field' do
        expect(strategy.sensitive_fields).to contain_exactly(field)
      end
    end
  end

  describe '#ensure_token' do
    let(:token_prefix) { nil }
    let(:token_generator) { nil }
    let(:token_owner_record) { test_class.new(token_prefix: token_prefix) }
    let(:devise_token) { 'devise-token' }

    subject(:token) { strategy.ensure_token(token_owner_record) }

    before do
      allow(Devise).to receive(:friendly_token).and_return(devise_token)
    end

    describe ':format_with_prefix option' do
      context 'when not set' do
        it 'generates a random token' do
          expect(token).to be_present
        end
      end

      context 'when set to a Symbol' do
        let(:token_prefix) { 'prefix-' }

        it 'generates a random token' do
          expect(token).to eq("#{token_prefix}#{devise_token}")
        end
      end

      context 'when set to not nil nor Symbol' do
        let(:options) { super().merge(format_with_prefix: false) }

        it 'generates a random token' do
          expect { token }.to raise_error(NotImplementedError)
        end
      end
    end

    describe ':token_generator option' do
      context 'when set to a lambda' do
        let(:options) { super().merge(token_generator: -> { 'generated token' }) }

        it 'generates a token by calling the #token_generator method' do
          expect(token).to eq('generated token')
        end
      end
    end

    describe ':routable_token option' do
      let(:random_bytes) { 'a' * described_class::RANDOM_BYTES_LENGTH }
      let(:cell_setting) { {} }
      let(:routable_token_payload) { { payload: { o: ->(_) { 'foo' } } } }

      shared_examples 'a routable token' do
        it 'delegates to RoutableTokenGenerator#generate_token' do
          generator = instance_double(Authn::TokenField::Generator::RoutableToken)
          expect(Authn::TokenField::Generator::RoutableToken)
            .to receive(:new).with(
              token_owner_record,
              routing_payload: routable_token_payload[:payload],
              prefix: token_prefix
            ).and_return(generator)
          expect(generator).to receive(:generate_token)

          token
        end
      end

      context 'with a { payload: } hash' do
        let(:options) { super().merge(routable_token: routable_token_payload) }

        it_behaves_like 'a routable token'
      end

      context 'with a { if:, payload: } hash when if: evaluates to true' do
        let(:options) do
          super().merge(
            routable_token: {
              if: ->(token_owner_record) { token_owner_record.respond_to?(:token_prefix) },
              **routable_token_payload
            }
          )
        end

        it_behaves_like 'a routable token'
      end

      context 'with a { if:, payload: } hash when if: evaluates to false' do
        let(:options) do
          super().merge(
            routable_token: {
              if: ->(token_owner_record) { token_owner_record.respond_to?(:no_method) },
              **routable_token_payload
            }
          )
        end

        it 'generates a random token' do
          expect(token).to eq("#{token_prefix}#{devise_token}")
        end
      end
    end

    describe ':unique option' do
      let(:token_prefix) { 'prefix-' }
      let(:options) { super().merge(unique: true, format_with_prefix: :token_prefix) }

      context 'when generated token is already in DB' do
        it 'generates a different token' do
          expect(strategy).to receive(:generate_token).and_return('prefix-token1')
          expect(strategy).to receive(:find_token_authenticatable).with('prefix-token1', true).and_return(true)

          expect(strategy).to receive(:generate_token).and_return('prefix-token2')
          expect(strategy).to receive(:find_token_authenticatable).with('prefix-token2', true).and_return(false)

          expect(token).to eq('prefix-token2')
        end
      end
    end
  end

  describe '#ensure_token!' do
    subject(:token) { strategy.ensure_token!(token_owner_record) }

    it 'populates and saves the token' do
      expect(token_owner_record).to receive(:save!)
      expect(token).to be_present
    end

    context 'when token is already present' do
      let(:token_owner_record) { test_class.new(token: 'foo') }

      it 'does not overwrite the token' do
        expect(token).to eq('foo')
      end
    end
  end

  describe '#reset_token!' do
    it 'populates and saves the token' do
      expect(token_owner_record).to receive(:save!)

      strategy.reset_token!(token_owner_record)

      expect(strategy.get_token(token_owner_record)).to be_present
    end

    context 'when token is already present' do
      let(:token_owner_record) { test_class.new(token: 'foo') }

      it 'overwrites the token' do
        expect(token_owner_record).to receive(:save!)

        strategy.reset_token!(token_owner_record)

        expect(strategy.get_token(token_owner_record)).to be_present
        expect(strategy.get_token(token_owner_record)).not_to eq('foo')
      end
    end

    context 'when database is not in read & write' do
      it 'does not save the token the token' do
        expect(Gitlab::Database).to receive(:read_write?).and_return(false)
        expect(token_owner_record).not_to receive(:save!)

        strategy.reset_token!(token_owner_record)

        expect(strategy.get_token(token_owner_record)).to be_present
      end
    end
  end

  describe '#expires_at' do
    let(:options) { super().merge(expires_at: ->(_) { 1.day.from_now }) }

    before do
      strategy.ensure_token(token_owner_record)
    end

    it 'returns the expires_at date' do
      expect(strategy.expires_at(token_owner_record)).to be_within(1.minute).of(1.day.from_now)
    end
  end

  describe '#expired?' do
    before do
      strategy.ensure_token(token_owner_record)
    end

    context 'when expires_at is in the future' do
      let(:options) { super().merge(expires_at: ->(_) { 1.day.from_now }) }

      it 'returns false when expires_at is in the future' do
        expect(strategy.expired?(token_owner_record)).to be(false)
      end
    end

    context 'when expires_at is in the past' do
      let(:options) { super().merge(expires_at: ->(_) { 1.day.ago }) }

      it 'returns true when expires_at is in the past' do
        expect(strategy.expired?(token_owner_record)).to be(true)
      end
    end
  end

  describe '#expirable?' do
    context 'when expires_at is not given' do
      it { is_expected.not_to be_expirable }
    end

    context 'when expires_at is given' do
      let(:options) { super().merge(expires_at: ->(_) { 1.day.from_now }) }

      it { is_expected.to be_expirable }
    end
  end

  describe '#token_with_expiration' do
    it 'delegates to API::Support::TokenWithExpiration' do
      expect(API::Support::TokenWithExpiration).to receive(:new).with(strategy, token_owner_record)

      strategy.token_with_expiration(token_owner_record)
    end
  end
end
