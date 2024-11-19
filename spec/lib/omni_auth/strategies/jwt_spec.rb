# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::Jwt do
  include Rack::Test::Methods
  include DeviseHelpers

  describe '#decoded' do
    subject(:jwt_strategy) { described_class.new({}) }

    let(:timestamp) { Time.now.to_i }
    let(:jwt_config) { Devise.omniauth_configs[:jwt] }
    let(:claims) do
      {
        id: 123,
        name: "user_example",
        email: "user@example.com",
        iat: timestamp
      }
    end

    let(:algorithm) { 'HS256' }
    let(:secret) { jwt_config.strategy.secret }
    let(:private_key) { secret }
    let(:payload) { JWT.encode(claims, private_key, algorithm) }

    before do
      subject.options[:secret] = secret
      subject.options[:algorithm] = algorithm

      # We use Rack::Request instead of ActionDispatch::Request because
      # Rack::Test::Methods enables testing of this module.
      expect_next_instance_of(Rack::Request) do |rack_request|
        expect(rack_request).to receive(:params).and_return('jwt' => payload)
      end
    end

    ecdsa_named_curves = {
      'ES256' => 'prime256v1',
      'ES384' => 'secp384r1',
      'ES512' => 'secp521r1'
    }.freeze

    {
      OpenSSL::PKey::RSA => %w[RS256 RS384 RS512],
      OpenSSL::PKey::EC => %w[ES256 ES384 ES512],
      String => %w[HS256 HS384 HS512]
    }.each do |private_key_class, algorithms|
      algorithms.each do |algorithm|
        context "when the #{algorithm} algorithm is used" do
          let(:algorithm) { algorithm }
          let(:secret) do
            if private_key_class == OpenSSL::PKey::RSA
              private_key_class.generate(2048)
                .to_pem
            elsif private_key_class == OpenSSL::PKey::EC
              private_key_class.generate(ecdsa_named_curves[algorithm])
                .to_pem
            else
              private_key_class.new(jwt_config.strategy.secret)
            end
          end

          let(:private_key) { private_key_class ? private_key_class.new(secret) : secret }

          it 'decodes the user information', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463691' do
            result = subject.decoded

            expect(result).to eq(claims.stringify_keys)
          end
        end
      end
    end

    context 'required claims is missing' do
      let(:claims) do
        {
          id: 123,
          email: "user@example.com",
          iat: timestamp
        }
      end

      it 'raises error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463692' do
        expect { subject.decoded }.to raise_error(OmniAuth::Strategies::Jwt::ClaimInvalid)
      end
    end

    context 'when valid_within is specified but iat attribute is missing in response' do
      let(:claims) do
        {
          id: 123,
          name: "user_example",
          email: "user@example.com"
        }
      end

      before do
        # Omniauth config values are always strings!
        subject.options[:valid_within] = 2.days.to_s
      end

      it 'raises error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463693' do
        expect { subject.decoded }.to raise_error(OmniAuth::Strategies::Jwt::ClaimInvalid)
      end
    end

    context 'when timestamp claim is too skewed from present' do
      let(:claims) do
        {
          id: 123,
          name: "user_example",
          email: "user@example.com",
          iat: timestamp - 10.minutes.to_i
        }
      end

      before do
        # Omniauth config values are always strings!
        subject.options[:valid_within] = 2.seconds.to_s
      end

      it 'raises error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/463694' do
        expect { subject.decoded }.to raise_error(OmniAuth::Strategies::Jwt::ClaimInvalid)
      end
    end

    context 'when the JWT is larger than 10KB' do
      def email_local_part
        'really_long_email' * 500
      end

      let(:claims) do
        {
          id: 123,
          name: "user_example",
          email: "#{email_local_part}@example.com",
          iat: timestamp
        }
      end

      it 'raises error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/482939' do
        expect { jwt_strategy.decoded }.to raise_error(OmniAuth::Strategies::Jwt::JwtTooLarge)
      end
    end
  end
end
