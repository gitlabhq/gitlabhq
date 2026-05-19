# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::RunnerRegistrationToken, feature_category: :system_access do
  describe '.prefix?' do
    subject(:prefix) { described_class.prefix?(token) }

    context 'for runner registration token prefix' do
      let(:token) { ::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX }

      it { is_expected.to be_truthy }
    end

    context 'for a token starting with the registration prefix' do
      let(:token) { "#{::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}sometoken" }

      it { is_expected.to be_truthy }
    end

    it 'returns false for runner authentication token prefix' do
      expect(described_class.prefix?(::Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX)).to be_falsey
    end

    it 'returns false for invalid prefix' do
      expect(described_class.prefix?('invalid-prefix')).to be_falsey
    end
  end

  describe '#initialize' do
    let(:plaintext) { "#{::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX}sometoken" }

    subject(:token) { described_class.new(plaintext, :api_admin_token) }

    it 'sets revocable to nil' do
      expect(token.revocable).to be_nil
    end

    it 'sets source' do
      expect(token.source).to eq(:api_admin_token)
    end
  end
end
