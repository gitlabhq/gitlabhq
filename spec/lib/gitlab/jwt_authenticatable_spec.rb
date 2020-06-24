# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JwtAuthenticatable do
  let(:test_class) do
    Class.new do
      include Gitlab::JwtAuthenticatable

      def self.secret_path
        Rails.root.join('tmp', 'tests', '.jwt_shared_secret')
      end
    end
  end

  before do
    begin
      File.delete(test_class.secret_path)
    rescue Errno::ENOENT
    end

    test_class.write_secret
  end

  describe '.secret' do
    subject(:secret) { test_class.secret }

    it 'returns 32 bytes' do
      expect(secret).to be_a(String)
      expect(secret.length).to eq(32)
      expect(secret.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it 'accepts a trailing newline' do
      File.open(test_class.secret_path, 'a') { |f| f.write "\n" }

      expect(secret.length).to eq(32)
    end

    it 'raises an exception if the secret file cannot be read' do
      File.delete(test_class.secret_path)

      expect { secret }.to raise_exception(Errno::ENOENT)
    end

    it 'raises an exception if the secret file contains the wrong number of bytes' do
      File.truncate(test_class.secret_path, 0)

      expect { secret }.to raise_exception(RuntimeError)
    end
  end

  describe '.write_secret' do
    it 'uses mode 0600' do
      expect(File.stat(test_class.secret_path).mode & 0777).to eq(0600)
    end

    it 'writes base64 data' do
      bytes = Base64.strict_decode64(File.read(test_class.secret_path))

      expect(bytes).not_to be_empty
    end
  end

  describe '.decode_jwt_for_issuer' do
    let(:payload) { { 'iss' => 'test_issuer' } }

    it 'accepts a correct header' do
      encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

      expect { test_class.decode_jwt_for_issuer('test_issuer', encoded_message) }.not_to raise_error
    end

    it 'raises an error when the JWT is not signed' do
      encoded_message = JWT.encode(payload, nil, 'none')

      expect { test_class.decode_jwt_for_issuer('test_issuer', encoded_message) }.to raise_error(JWT::DecodeError)
    end

    it 'raises an error when the header is signed with the wrong secret' do
      encoded_message = JWT.encode(payload, 'wrongsecret', 'HS256')

      expect { test_class.decode_jwt_for_issuer('test_issuer', encoded_message) }.to raise_error(JWT::DecodeError)
    end

    it 'raises an error when the issuer is incorrect' do
      payload['iss'] = 'somebody else'
      encoded_message = JWT.encode(payload, test_class.secret, 'HS256')

      expect { test_class.decode_jwt_for_issuer('test_issuer', encoded_message) }.to raise_error(JWT::DecodeError)
    end
  end
end
