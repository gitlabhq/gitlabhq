# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::JobToken::Jwt::Encode, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:build) { create(:ci_build, :running) }
  let_it_be(:another_object) { create(:user) }
  let_it_be(:key) { OpenSSL::PKey::RSA.generate(2048) }

  before do
    allow(described_class).to receive(:key).and_return(key)
  end

  describe '#jwt' do
    subject(:token) { described_class.new(build).jwt }

    let(:jwt) { token&.delete_prefix(described_class.token_prefix) }
    let(:decoded_token) { JWT.decode(jwt, key.public_key, true, { algorithm: 'RS256' }) }

    it { is_expected.to start_with(Ci::Build::TOKEN_PREFIX) }

    it 'creates a valid JWT' do
      payload, header = decoded_token

      expect(header).to match(
        'kid' => key.public_key.to_jwk[:kid],
        'typ' => 'JWT',
        'alg' => 'RS256'
      )

      expect(payload).to match(a_hash_including(
        'sub' => build.to_global_id.to_s,
        'iss' => ::Gitlab::Authz::Token::Encode::ISSUER,
        'aud' => ::Gitlab::Authz::Token::Encode::AUDIENCE
      ))
    end

    context 'when the build is invalid' do
      where(:build) do
        [nil, ref(:another_object)]
      end

      with_them do
        it 'raises an error' do
          expect { token }.to raise_error(::Gitlab::Authz::Token::Encode::InvalidSubjectForTokenError)
        end
      end
    end

    context 'when the build is not persisted' do
      let_it_be(:build) { FactoryBot.build(:ci_build) }

      it { is_expected.to be_nil }
    end

    describe 'setting the expire time' do
      let(:default_expire_time) { JSONWebToken::Token::DEFAULT_EXPIRE_TIME }
      let(:leeway) { described_class::LEEWAY }

      subject(:expire_time) { decoded_token[0]['exp'] - decoded_token[0]['iat'] }

      describe 'job timeout' do
        before do
          build.metadata.timeout = job_timeout
        end

        context 'when no timeout is set on the job' do
          let(:job_timeout) { nil }

          it { is_expected.to eq default_expire_time + leeway }
        end

        context 'when the timeout is greater than the default expire time' do
          let(:job_timeout) { default_expire_time + 10 }

          it { is_expected.to eq job_timeout + leeway }
        end

        context 'when the timeout on the job is less than the default expire time' do
          let(:job_timeout) { default_expire_time - 10 }

          it { is_expected.to eq default_expire_time + leeway }
        end
      end
    end
  end
end
