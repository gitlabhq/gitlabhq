# frozen_string_literal: true

require 'json'
require 'active_support/testing/time_helpers'

RSpec.describe JSONWebToken::HMACToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:secret) { 'shh secret squirrel' }

  shared_examples 'a valid, non-expired token' do
    it 'is an Array with two elements' do
      expect(decoded_token).to be_a(Array)
      expect(decoded_token.count).to eq(2)
    end

    it 'contains the following keys in the first Array element Hash - jti, iat, nbf, exp' do
      expect(decoded_token[0].keys).to include('jti', 'iat', 'nbf', 'exp')
    end

    it 'contains the following keys in the second Array element Hash - typ and alg' do
      expect(decoded_token[1]['typ']).to eql('JWT')
      expect(decoded_token[1]['alg']).to eql('HS256')
    end
  end

  describe '.decode' do
    let(:leeway) { described_class::LEEWAY }
    let(:decoded_token) { described_class.decode(encoded_token, secret, leeway: leeway) }

    context 'with an invalid token' do
      context 'that is junk' do
        let(:encoded_token) { 'junk' }

        it "raises exception saying 'Not enough or too many segments'" do
          expect { decoded_token }.to raise_error(JWT::DecodeError, 'Not enough or too many segments')
        end
      end

      context 'that has been fiddled with' do
        let(:encoded_token) do
          described_class.new(secret).encoded.tap { |token| token[0] = 'E' }
        end

        it "raises exception saying 'Invalid segment encoding'" do
          expect { decoded_token }.to raise_error(JWT::DecodeError, 'Invalid segment encoding')
        end
      end

      context 'that was generated using a different secret' do
        let(:encoded_token) { described_class.new('some other secret').encoded }

        it "raises exception saying 'Signature verification failed" do
          expect { decoded_token }.to raise_error(JWT::VerificationError, 'Signature verification failed')
        end
      end

      context 'that is expired' do
        # Needs the ! so freeze_time() is effective
        let!(:encoded_token) { described_class.new(secret).encoded }

        it "raises exception saying 'Signature has expired'" do
          # Needs to be 120 seconds, because the default expiry is 60 seconds
          # with an additional 60 second leeway.
          travel_to(Time.now + 120) do
            expect { decoded_token }.to raise_error(JWT::ExpiredSignature, 'Signature has expired')
          end
        end
      end
    end

    context 'with a valid token' do
      let(:encoded_token) do
        hmac_token = described_class.new(secret)
        hmac_token.expire_time = Time.now + expire_time
        hmac_token.encoded
      end

      context 'that has expired' do
        let(:expire_time) { 0 }

        around do |example|
          travel_to(Time.now + 1) { example.run }
        end

        context 'with the default leeway' do
          it_behaves_like 'a valid, non-expired token'
        end

        context 'with a leeway of 0 seconds' do
          let(:leeway) { 0 }

          it "raises exception saying 'Signature has expired'" do
            expect { decoded_token }.to raise_error(JWT::ExpiredSignature, 'Signature has expired')
          end
        end
      end

      context 'that has not expired' do
        let(:expire_time) { described_class::DEFAULT_EXPIRE_TIME }

        it_behaves_like 'a valid, non-expired token'
      end
    end
  end

  describe '#encoded' do
    let(:decoded_token) { described_class.decode(encoded_token, secret) }

    context 'without data' do
      let(:encoded_token) { described_class.new(secret).encoded }

      it_behaves_like 'a valid, non-expired token'
    end

    context 'with data' do
      let(:data) { { secret_key: 'secret value' }.to_json }
      let(:encoded_token) do
        ec = described_class.new(secret)
        ec[:data] = data
        ec.encoded
      end

      it_behaves_like 'a valid, non-expired token'

      it "contains the 'data' key in the first Array element Hash" do
        expect(decoded_token[0]).to have_key('data')
      end

      it 'can re-read back the data' do
        expect(decoded_token[0]['data']).to eql(data)
      end
    end
  end
end
