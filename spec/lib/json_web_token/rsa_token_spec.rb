# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JSONWebToken::RSAToken, feature_category: :shared do
  let_it_be(:rsa_key) do
    OpenSSL::PKey::RSA.new <<-EOS.strip_heredoc
      -----BEGIN RSA PRIVATE KEY-----
      MIIBOgIBAAJBAMA5sXIBE0HwgIB40iNidN4PGWzOyLQK0bsdOBNgpEXkDlZBvnak
      OUgAPF+rME4PB0Yl415DabUI40T5UNmlwxcCAwEAAQJAZtY2pSwIFm3JAXIh0cZZ
      iXcAfiJ+YzuqinUOS+eW2sBCAEzjcARlU/o6sFQgtsOi4FOMczAd1Yx8UDMXMmrw
      2QIhAPBgVhJiTF09pdmeFWutCvTJDlFFAQNbrbo2X2x/9WF9AiEAzLgqMKeStSRu
      H9N16TuDrUoO8R+DPqriCwkKrSHaWyMCIFzMhE4inuKcSywBaLmiG4m3GQzs++Al
      A6PRG/PSTpQtAiBxtBg6zdf+JC3GH3zt/dA0/10tL4OF2wORfYQghRzyYQIhAL2l
      0ZQW+yLIZAGrdBFWYEAa52GZosncmzBNlsoTgwE4
      -----END RSA PRIVATE KEY-----
    EOS
  end

  let(:rsa_token) { described_class.new(nil) }
  let(:rsa_encoded) { rsa_token.encoded }

  before do
    allow_any_instance_of(described_class).to receive(:key).and_return(rsa_key)
  end

  context 'token' do
    context 'for valid key to be validated' do
      before do
        rsa_token['key'] = 'value'
      end

      subject { JWT.decode(rsa_encoded, rsa_key, true, { algorithm: 'RS256' }) }

      it { expect { subject }.not_to raise_error }
      it { expect(subject.first).to include('key' => 'value') }

      it do
        expect(subject.second).to eq(
          "typ" => "JWT",
          "alg" => "RS256",
          "kid" => "OGXY:4TR7:FAVO:WEM2:XXEW:E4FP:TKL7:7ACK:TZAF:D54P:SUIA:P3B2")
      end
    end

    context 'for invalid key to raise an exception' do
      let(:new_key) { OpenSSL::PKey::RSA.generate(3072) }

      subject { JWT.decode(rsa_encoded, new_key, true, { algorithm: 'RS256' }) }

      it { expect { subject }.to raise_error(JWT::DecodeError) }
    end
  end

  describe '.encode' do
    let(:payload) { { key: 'value' } }
    let(:kid) { rsa_key.public_key.to_jwk[:kid] }
    let(:headers) { { kid: kid, typ: 'JWT' } }

    it 'generates the JWT' do
      expect(JWT).to receive(:encode).with(payload, rsa_key, described_class::ALGORITHM, headers).and_call_original

      expect(described_class.encode(payload, rsa_key, kid)).to be_a(String)
    end
  end

  describe '.decode' do
    let(:decoded_token) { described_class.decode(rsa_encoded, rsa_key) }

    context 'with an invalid token' do
      context 'that is junk' do
        let(:rsa_encoded) { 'junk' }

        it "raises exception saying 'Not enough or too many segments'" do
          expect { decoded_token }.to raise_error(JWT::DecodeError, 'Not enough or too many segments')
        end
      end

      context 'that has been fiddled with' do
        let(:rsa_encoded) { rsa_token.encoded.tap { |token| token[0] = 'E' } }

        it "raises exception saying 'Invalid segment encoding'" do
          expect { decoded_token }.to raise_error(JWT::DecodeError, 'Invalid segment encoding')
        end
      end

      context 'that was generated using a different key' do
        let_it_be(:rsa_key_2) { OpenSSL::PKey::RSA.new 2048 }

        before do
          # rsa_key is used for encoding, and rsa_key_2 for decoding
          allow(JWT)
            .to receive(:decode)
            .with(rsa_encoded, rsa_key, true, { algorithm: described_class::ALGORITHM })
            .and_wrap_original do |original_method, *args|
            args[1] = rsa_key_2
            original_method.call(*args)
          end
        end

        it "raises exception saying 'Signature verification failed" do
          expect { decoded_token }.to raise_error(JWT::VerificationError, 'Signature verification failed')
        end
      end

      context 'that is expired' do
        # Needs the ! so freeze_time() is effective
        let!(:rsa_encoded) { rsa_token.encoded }

        it "raises exception saying 'Signature has expired'" do
          # Needs to be 120 seconds, because the default expiry is 60 seconds
          # with an additional 60 second leeway.
          travel_to(Time.current + 120) do
            expect { decoded_token }.to raise_error(JWT::ExpiredSignature, 'Signature has expired')
          end
        end
      end
    end
  end
end
