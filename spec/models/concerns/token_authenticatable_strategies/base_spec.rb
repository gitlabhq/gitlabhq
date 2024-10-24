# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatableStrategies::Base, feature_category: :system_access do
  let(:field) { 'token' }
  let(:digest_field) { "#{field}_digest" }
  let(:expires_at_field) { "#{field}_expires_at" }
  let(:options) { { unique: false } }
  let(:test_class) do
    Struct.new(:name, :token_prefix, field, digest_field, expires_at_field) do
      alias_method :read_attribute, :[]
    end
  end

  let(:concrete_strategy) do
    Class.new(described_class) do
      def get_token(instance)
        instance[token_field]
      end

      def set_token(instance, token)
        instance[token_field] = token if token
      end

      def token_set?(instance)
        instance[token_field].present?
      end
    end
  end

  let(:instance) { test_class.new }

  subject(:strategy) { concrete_strategy.new(test_class, field, options) }

  describe '.random_bytes' do
    it 'generates 16 random bytes' do
      expect(described_class.random_bytes.size).to eq(16)
    end
  end

  describe '.fabricate' do
    context 'when digest strategy is specified' do
      it 'fabricates digest strategy object' do
        strategy = described_class.fabricate(test_class, field, digest: true)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Digest
      end
    end

    context 'when encrypted strategy is specified' do
      it 'fabricates encrypted strategy object' do
        strategy = described_class.fabricate(test_class, field, encrypted: :required)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Encrypted
      end
    end

    context 'when no strategy is specified' do
      it 'fabricates insecure strategy object' do
        strategy = described_class.fabricate(test_class, field, something: :required)

        expect(strategy).to be_a TokenAuthenticatableStrategies::Insecure
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
      expect { strategy.find_token_authenticatable(instance) }.to raise_error(NotImplementedError)
    end
  end

  describe '#get_token' do
    subject(:strategy) { described_class.new(test_class, field, options) }

    it 'raises a NotImplementedError error' do
      expect { strategy.get_token(instance) }.to raise_error(NotImplementedError)
    end
  end

  describe '#set_token' do
    subject(:strategy) { described_class.new(test_class, field, options) }

    it 'raises a NotImplementedError error' do
      expect { strategy.set_token(instance, 'foo') }.to raise_error(NotImplementedError)
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
    let(:instance) { test_class.new(name: 'foo', token_prefix: token_prefix) }
    let(:random_bytes) { 'random-bytes' }

    subject(:token) { strategy.ensure_token(instance) }

    before do
      allow(described_class).to receive(:random_bytes).and_return(random_bytes)
    end

    describe ':format_with_prefix option' do
      context 'when not set' do
        it 'generates a random token' do
          expect(token).to be_present
        end
      end

      context 'when set to a Symbol' do
        let(:token_prefix) { 'prefix-' }
        let(:options) { super().merge(format_with_prefix: :token_prefix) }

        it 'generates a random token' do
          expect(Devise).to receive(:friendly_token).and_return('devise_token')

          expect(token).to eq("#{token_prefix}devise_token")
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
      let(:cell_setting) { {} }
      let(:options) do
        super().merge(
          routable_token: { n: ->(instance) { instance.name } },
          format_with_prefix: :token_prefix
        )
      end

      before do
        allow(Settings).to receive(:cell).and_return(cell_setting)
      end

      context 'when instance does not respond to #user' do
        it 'generates a non routable token' do
          expect(Devise).to receive(:friendly_token).and_return('devise_token')

          expect(token).to eq('devise_token')
        end
      end

      context 'when instance responds to #user' do
        let(:user) { build(:user) }

        before do
          stub_feature_flags(routable_token: user)
          allow(instance).to receive(:user).and_return(user)
        end

        context 'when Settings.cells.id is not present' do
          it 'generates a routable token' do
            expect(Base64.urlsafe_decode64(token)).to eq("n:foo\nr:#{random_bytes}")
          end
        end

        context 'when Settings.cells.id is present' do
          let(:cell_setting) { { id: 100 } }

          it 'generates a routable token' do
            expect(Base64.urlsafe_decode64(token)).to eq("c:#{cell_setting[:id].to_s(36)}\nn:foo\nr:#{random_bytes}")
          end
        end

        context 'with a prefix set' do
          let(:token_prefix) { 'prefix-' }

          it 'generates a routable token' do
            expect(token).to start_with(token_prefix)
            expect(Base64.urlsafe_decode64(token.delete_prefix(token_prefix))).to eq("n:foo\nr:#{random_bytes}")
          end
        end
      end
    end
  end

  describe '#ensure_token!' do
    subject(:token) { strategy.ensure_token!(instance) }

    it 'populates and saves the token' do
      expect(instance).to receive(:save!)
      expect(token).to be_present
    end

    context 'when token is already present' do
      let(:instance) { test_class.new(token: 'foo') }

      it 'does not overwrite the token' do
        expect(token).to eq('foo')
      end
    end
  end

  describe '#reset_token!' do
    it 'populates and saves the token' do
      expect(instance).to receive(:save!)

      strategy.reset_token!(instance)

      expect(strategy.get_token(instance)).to be_present
    end

    context 'when token is already present' do
      let(:instance) { test_class.new(token: 'foo') }

      it 'overwrites the token' do
        expect(instance).to receive(:save!)

        strategy.reset_token!(instance)

        expect(strategy.get_token(instance)).to be_present
        expect(strategy.get_token(instance)).not_to eq('foo')
      end
    end

    context 'when database is not in read & write' do
      it 'does not save the token the token' do
        expect(Gitlab::Database).to receive(:read_write?).and_return(false)
        expect(instance).not_to receive(:save!)

        strategy.reset_token!(instance)

        expect(strategy.get_token(instance)).to be_present
      end
    end
  end

  describe '#expires_at' do
    let(:options) { super().merge(expires_at: ->(_) { 1.day.from_now }) }

    before do
      strategy.ensure_token(instance)
    end

    it 'returns the expires_at date' do
      expect(strategy.expires_at(instance)).to be_within(1.minute).of(1.day.from_now)
    end
  end

  describe '#expired?' do
    before do
      strategy.ensure_token(instance)
    end

    context 'when expires_at is in the future' do
      let(:options) { super().merge(expires_at: ->(_) { 1.day.from_now }) }

      it 'returns false when expires_at is in the future' do
        expect(strategy.expired?(instance)).to be(false)
      end
    end

    context 'when expires_at is in the past' do
      let(:options) { super().merge(expires_at: ->(_) { 1.day.ago }) }

      it 'returns true when expires_at is in the past' do
        expect(strategy.expired?(instance)).to be(true)
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
      expect(API::Support::TokenWithExpiration).to receive(:new).with(strategy, instance)

      strategy.token_with_expiration(instance)
    end
  end
end
