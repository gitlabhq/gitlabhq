# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GoogleCloudPlatform::Jwt, feature_category: :shared do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:claims) { { audience: 'http://sandbox.test', wlif: 'http://wlif.test' } }
  let(:jwt) { described_class.new(project: project, user: user, claims: claims) }

  describe '#encoded' do
    let_it_be(:rsa_key) { OpenSSL::PKey::RSA.generate(3072) }
    let_it_be(:rsa_key_data) { rsa_key.to_s }

    subject(:encoded) { jwt.encoded }

    before do
      stub_application_setting(ci_jwt_signing_key: rsa_key_data)
    end

    it 'creates a valid jwt' do
      payload, headers = JWT.decode(encoded, rsa_key.public_key, true, { algorithm: 'RS256' })

      expect(payload).to include(
        'root_namespace_path' => project.root_namespace.full_path,
        'root_namespace_id' => project.root_namespace.id.to_s,
        'wlif' => claims[:wlif],
        'aud' => claims[:audience],
        'project_id' => project.id.to_s,
        'project_path' => project.full_path,
        'user_id' => user.id.to_s,
        'user_email' => user.email,
        'sub' => "project_#{project.id}_user_#{user.id}",
        'iss' => Gitlab.config.gitlab.url
      )

      expect(headers).to include(
        'kid' => rsa_key.public_key.to_jwk[:kid]
      )
    end

    context 'with missing jwt audience' do
      let(:claims) { { wlif: 'http://wlif.test' } }

      it 'raises an ArgumentError' do
        expect { encoded }.to raise_error(ArgumentError, described_class::JWT_OPTIONS_ERROR)
      end
    end

    context 'with missing jwt wlif' do
      let(:claims) { { audience: 'http://sandbox.test' } }

      it 'raises an ArgumentError' do
        expect { encoded }.to raise_error(ArgumentError, described_class::JWT_OPTIONS_ERROR)
      end
    end

    context 'with no ci signing key' do
      before do
        stub_application_setting(ci_jwt_signing_key: nil)
      end

      it 'raises a NoSigningKeyError' do
        expect { encoded }.to raise_error(described_class::NoSigningKeyError)
      end
    end

    context 'with oidc_issuer_url feature flag disabled' do
      before do
        stub_feature_flags(oidc_issuer_url: false)
        # Settings.gitlab.base_url and Gitlab.config.gitlab.url are the
        # same for test. Changing that to assert the proper behavior here.
        allow(Settings.gitlab).to receive(:base_url).and_return('test.dev')
      end

      it 'uses a different issuer' do
        payload, _ = JWT.decode(encoded, rsa_key.public_key, true, { algorithm: 'RS256' })

        expect(payload).to include(
          'iss' => Settings.gitlab.base_url
        )
      end
    end
  end
end
