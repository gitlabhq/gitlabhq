# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DoorkeeperSecretStoring::Token::UniqueApplicationToken, feature_category: :system_access do
  describe '.generate' do
    subject(:generate) { described_class.generate }

    it 'generates a token with a prefix followed by a 32 character hex string' do
      expect(generate).to match(/gloas-\h{32}/)
    end

    context 'with custom instance prefix' do
      let_it_be(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'starts with instance prefix' do
        expect(generate).to match(/instanceprefix-gloas-\h{32}/)
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it 'starts with the default prefix' do
          expect(generate).to match(/gloas-\h{32}/)
        end
      end
    end
  end

  describe '.prefix_for_oauth_application_secret' do
    subject(:prefix_for_oauth_application_secret) { described_class.prefix_for_oauth_application_secret }

    it 'defaults to OAUTH_APPLICATION_SECRET_PREFIX_FORMAT' do
      expect(prefix_for_oauth_application_secret).to eq(described_class::OAUTH_APPLICATION_SECRET_PREFIX_FORMAT)
    end

    context 'with custom instance prefix' do
      let_it_be(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'starts with instance prefix' do
        expect(prefix_for_oauth_application_secret).to eq('instanceprefix-gloas-%{token}')
      end

      context 'with feature flag custom_prefix_for_all_token_types disabled' do
        before do
          stub_feature_flags(custom_prefix_for_all_token_types: false)
        end

        it 'defaults to OAUTH_APPLICATION_SECRET_PREFIX_FORMAT' do
          expect(prefix_for_oauth_application_secret).to eq(described_class::OAUTH_APPLICATION_SECRET_PREFIX_FORMAT)
        end
      end
    end
  end
end
