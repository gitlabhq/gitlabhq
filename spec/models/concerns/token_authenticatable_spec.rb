# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TokenAuthenticatable, feature_category: :shared do
  let(:field) { 'token' }
  let(:digest_field) { "#{field}_digest" }
  let(:encrypted_field) { "#{field}_encrypted" }
  let(:base_class) do
    Struct.new(:name, :token_prefix, field) do
      include TokenAuthenticatable

      alias_method :read_attribute, :[]

      def has_attribute?(_)
        true
      end
    end
  end

  let(:options) { {} }

  let(:test_class) do
    Class.new(base_class).tap do |klass|
      klass.send(:add_authentication_token_field, field, options)
    end
  end

  subject(:instance) { test_class.new }

  describe 'setting same token field multiple times' do
    let(:test_class) do
      Class.new(base_class).tap do |klass|
        klass.send(:add_authentication_token_field, field, options)
        klass.send(:add_authentication_token_field, field, options)
      end
    end

    it 'raises error' do
      expect { test_class.new }.to raise_error(ArgumentError)
    end
  end

  describe '.encrypted_token_authenticatable_fields' do
    subject(:token_authenticatable_fields) { test_class.encrypted_token_authenticatable_fields }

    it { is_expected.to be_empty }

    context 'with encrypted: true' do
      let(:options) { { encrypted: true } }

      it { is_expected.to contain_exactly(field) }
    end

    context 'with digest: true' do
      let(:options) { { digest: true } }

      it { is_expected.to be_empty }
    end
  end

  describe '.token_authenticatable_fields' do
    subject(:token_authenticatable_fields) { test_class.token_authenticatable_fields }

    it { is_expected.to contain_exactly(field) }

    context 'with encrypted: true' do
      let(:options) { { encrypted: true } }

      it { is_expected.to contain_exactly(field) }
    end

    context 'with digest: true' do
      let(:options) { { digest: true } }

      it { is_expected.to contain_exactly(field) }
    end
  end

  describe '.token_authenticatable_sensitive_fields' do
    subject(:token_authenticatable_fields) { test_class.token_authenticatable_sensitive_fields }

    it { is_expected.to contain_exactly(field.to_sym) }

    context 'with encrypted: true' do
      let(:options) { { encrypted: true } }

      it { is_expected.to contain_exactly(field.to_sym, encrypted_field.to_sym) }
    end

    context 'with digest: true' do
      let(:options) { { digest: true } }

      it { is_expected.to contain_exactly(field.to_sym, digest_field.to_sym) }
    end

    context 'with expires_at option' do
      let(:options) { { expires_at: -> { Time.current } } }

      it { is_expected.to contain_exactly(field.to_sym) }
    end
  end

  describe 'dynamic methods' do
    let(:strategy) { instance_double(Authn::TokenField::Base, sensitive_fields: []) }

    before do
      allow(Authn::TokenField::Base)
        .to receive(:fabricate).with(anything, field, options)
        .and_return(strategy)
    end

    describe '#<field>' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:get_token).with(instance)

        instance.public_send(field)
      end
    end

    describe '#set_<field>' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:set_token).with(instance, 'foo')

        instance.public_send(:"set_#{field}", 'foo')
      end
    end

    describe '#ensure_<field>' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:ensure_token).with(instance)

        instance.public_send(:"ensure_#{field}")
      end
    end

    describe '#ensure_<field>!' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:ensure_token!).with(instance)

        instance.public_send(:"ensure_#{field}!")
      end
    end

    describe '#reset_<field>!' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:reset_token!).with(instance)

        instance.public_send(:"reset_#{field}!")
      end
    end

    describe '#<field>_matches?' do
      it 'delegates to strategy' do
        instance.public_send(:"#{field}=", 'foo')

        expect(instance.public_send(:"#{field}_matches?", 'bar')).to eq(false)
      end
    end

    describe '#<field>_expires_at' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:expires_at).with(instance)

        instance.public_send(:"#{field}_expires_at")
      end
    end

    describe '#<field>_expired?' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:expired?).with(instance)

        instance.public_send(:"#{field}_expired?")
      end
    end

    describe '#<field>_with_expiration' do
      it 'delegates to strategy' do
        expect(strategy).to receive(:token_with_expiration).with(instance)

        instance.public_send(:"#{field}_with_expiration")
      end
    end
  end
end
