# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JwtAuthenticatable, feature_category: :system_access do
  let(:test_class) do
    Class.new do
      include Gitlab::JwtAuthenticatable

      def self.secret_path
        Rails.root.join('tmp', 'tests', '.jwt_shared_secret')
      end
    end
  end

  before do
    FileUtils.rm_f(test_class.secret_path)

    test_class.write_secret
  end

  shared_examples 'reading secret from the secret path' do
    it 'returns 32 bytes' do
      expect(secret).to be_a(String)
      expect(secret.length).to eq(32)
      expect(secret.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it 'accepts a trailing newline' do
      File.open(secret_path, 'a') { |f| f.write "\n" }

      expect(secret.length).to eq(32)
    end

    it 'raises an exception if the secret file cannot be read' do
      File.delete(secret_path)

      expect { secret }.to raise_exception(Errno::ENOENT)
    end

    it 'raises an exception if the secret file contains the wrong number of bytes' do
      File.truncate(secret_path, 0)

      expect { secret }.to raise_exception(RuntimeError)
    end
  end

  describe '.secret' do
    it_behaves_like 'reading secret from the secret path' do
      subject(:secret) { test_class.secret }

      let(:secret_path) { test_class.secret_path }
    end
  end

  describe '.read_secret' do
    it_behaves_like 'reading secret from the secret path' do
      subject(:secret) { test_class.read_secret(secret_path) }

      let(:secret_path) { test_class.secret_path }
    end
  end

  describe '.write_secret' do
    context 'without an input' do
      it 'uses mode 0600' do
        expect(File.stat(test_class.secret_path).mode & 0777).to eq(0600)
      end

      it 'writes base64 data' do
        bytes = Base64.strict_decode64(File.read(test_class.secret_path))

        expect(bytes).not_to be_empty
      end
    end

    context 'with an input' do
      let(:another_path) do
        Rails.root.join('tmp', 'tests', '.jwt_another_shared_secret')
      end

      after do
        File.delete(another_path)
      rescue Errno::ENOENT
      end

      it 'uses mode 0600' do
        test_class.write_secret(another_path)
        expect(File.stat(another_path).mode & 0777).to eq(0600)
      end

      it 'writes base64 data' do
        test_class.write_secret(another_path)
        bytes = Base64.strict_decode64(File.read(another_path))

        expect(bytes).not_to be_empty
      end
    end
  end

  describe '.decode_jwt' do |decode|
    let(:payload) { {} }

    context 'use included class secret' do
      it 'accepts a correct header' do
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message) }.not_to raise_error
      end

      it 'raises an error when the JWT is not signed' do
        encoded_message = JWT.encode(payload, nil, 'none')

        expect { test_class.decode_jwt(encoded_message) }.to raise_error(JWT::DecodeError)
      end

      it 'raises an error when the header is signed with the wrong secret' do
        encoded_message = JWT.encode(payload, 'wrongsecret', 'HS256')

        expect { test_class.decode_jwt(encoded_message) }.to raise_error(JWT::DecodeError)
      end
    end

    context 'use an input secret' do
      let(:another_secret) { 'another secret' }

      it 'accepts a correct header' do
        encoded_message = JWT.encode(payload, another_secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, another_secret) }.not_to raise_error
      end

      it 'raises an error when the JWT is not signed' do
        encoded_message = JWT.encode(payload, nil, 'none')

        expect { test_class.decode_jwt(encoded_message, another_secret) }.to raise_error(JWT::DecodeError)
      end

      it 'raises an error when the header is signed with the wrong secret' do
        encoded_message = JWT.encode(payload, 'wrongsecret', 'HS256')

        expect { test_class.decode_jwt(encoded_message, another_secret) }.to raise_error(JWT::DecodeError)
      end
    end

    context 'issuer option' do
      let(:payload) { { 'iss' => 'test_issuer' } }

      it 'returns decoded payload if issuer is correct' do
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')
        decoded_payload = test_class.decode_jwt(encoded_message, issuer: 'test_issuer')

        expect(decoded_payload[0]).to match a_hash_including('iss' => 'test_issuer')
      end

      it 'raises an error when the issuer is incorrect' do
        payload['iss'] = 'somebody else'
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, issuer: 'test_issuer') }.to raise_error(JWT::DecodeError)
      end

      it 'raises an error when the issuer is nil' do
        payload['iss'] = nil
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, issuer: 'test_issuer') }.to raise_error(JWT::DecodeError)
      end
    end

    context 'audience option' do
      let(:payload) { { 'aud' => 'test_audience' } }

      it 'returns decoded payload if audience is correct' do
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')
        decoded_payload = test_class.decode_jwt(encoded_message, audience: 'test_audience')

        expect(decoded_payload[0]).to match a_hash_including('aud' => 'test_audience')
      end

      it 'raises an error when the audience is incorrect' do
        payload['aud'] = 'somebody else'
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, audience: 'test_audience') }.to raise_error(JWT::DecodeError)
      end

      it 'raises an error when the audience is nil' do
        payload['aud'] = nil
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, audience: 'test_audience') }.to raise_error(JWT::DecodeError)
      end
    end

    context 'iat_after option' do
      it 'returns decoded payload if iat is valid' do
        freeze_time do
          encoded_message = JWT.encode(payload.merge(iat: (Time.current - 10.seconds).to_i), test_class.secret, 'HS256')
          payload = test_class.decode_jwt(encoded_message, iat_after: Time.current - 20.seconds)

          expect(payload[0]).to match a_hash_including('iat' => be_a(Integer))
        end
      end

      it 'raises an error if iat is invalid' do
        encoded_message = JWT.encode(payload.merge(iat: Time.current.to_i + 1), test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, iat_after: true) }.to raise_error(JWT::DecodeError)
      end

      it 'raises InvalidPayload exception if iat is a string' do
        expect do
          JWT.encode(payload.merge(iat: 'wrong'), test_class.secret, 'HS256')
        end.to raise_error(JWT::InvalidPayload)
      end

      it 'raises an error if iat is absent' do
        encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

        expect { test_class.decode_jwt(encoded_message, iat_after: true) }.to raise_error(JWT::DecodeError)
      end

      it 'raises an error if iat is too far in the past' do
        freeze_time do
          encoded_message = JWT.encode(payload.merge(iat: (Time.current - 30.seconds).to_i), test_class.secret, 'HS256')
          expect do
            test_class.decode_jwt(encoded_message, iat_after: Time.current - 20.seconds)
          end.to raise_error(JWT::ExpiredSignature, 'Token has expired')
        end
      end
    end

    context 'algorithm' do
      context 'with default algorithm' do
        it 'accepts a correct header' do
          encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

          expect { test_class.decode_jwt(encoded_message) }.not_to raise_error
        end
      end

      context 'with provided algorithm' do
        it 'accepts a correct header' do
          encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

          expect { test_class.decode_jwt(encoded_message, algorithm: 'HS256') }.not_to raise_error
        end

        it 'raises an error when the header is signed with the wrong algorithm' do
          encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

          expect { test_class.decode_jwt(encoded_message, algorithm: 'RS256') }.to raise_error(JWT::DecodeError)
        end
      end
    end
  end
end
