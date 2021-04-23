# frozen_string_literal: true

RSpec.shared_examples 'a gitlab jwt token' do
  let_it_be(:base_secret) { SecureRandom.base64(64) }

  let(:jwt_secret) do
    OpenSSL::HMAC.hexdigest(
      'SHA256',
      base_secret,
      described_class::HMAC_KEY
    )
  end

  before do
    allow(Settings).to receive(:attr_encrypted_db_key_base).and_return(base_secret)
  end

  describe '#secret' do
    subject { described_class.secret }

    it { is_expected.to eq(jwt_secret) }
  end

  describe '#decode' do
    let(:encoded_jwt_token) { jwt_token.encoded }

    subject(:decoded_jwt_token) { described_class.decode(encoded_jwt_token) }

    context 'with a custom payload' do
      let(:personal_access_token) { create(:personal_access_token) }
      let(:jwt_token) { described_class.new.tap { |jwt_token| jwt_token['token'] = personal_access_token.token } }

      it 'returns the correct token' do
        expect(decoded_jwt_token['token']).to eq jwt_token['token']
      end

      it 'returns nil and logs the exception after expiration' do
        travel_to((described_class::HMAC_EXPIRES_IN + 1.minute).ago) do
          encoded_jwt_token
        end

        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(JWT::ExpiredSignature))

        expect(decoded_jwt_token).to be_nil
      end
    end
  end
end
