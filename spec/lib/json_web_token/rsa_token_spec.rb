# frozen_string_literal: true

describe JSONWebToken::RSAToken do
  let(:rsa_key) do
    OpenSSL::PKey::RSA.new <<-eos.strip_heredoc
      -----BEGIN RSA PRIVATE KEY-----
      MIIBOgIBAAJBAMA5sXIBE0HwgIB40iNidN4PGWzOyLQK0bsdOBNgpEXkDlZBvnak
      OUgAPF+rME4PB0Yl415DabUI40T5UNmlwxcCAwEAAQJAZtY2pSwIFm3JAXIh0cZZ
      iXcAfiJ+YzuqinUOS+eW2sBCAEzjcARlU/o6sFQgtsOi4FOMczAd1Yx8UDMXMmrw
      2QIhAPBgVhJiTF09pdmeFWutCvTJDlFFAQNbrbo2X2x/9WF9AiEAzLgqMKeStSRu
      H9N16TuDrUoO8R+DPqriCwkKrSHaWyMCIFzMhE4inuKcSywBaLmiG4m3GQzs++Al
      A6PRG/PSTpQtAiBxtBg6zdf+JC3GH3zt/dA0/10tL4OF2wORfYQghRzyYQIhAL2l
      0ZQW+yLIZAGrdBFWYEAa52GZosncmzBNlsoTgwE4
      -----END RSA PRIVATE KEY-----
    eos
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

      it { expect {subject}.not_to raise_error }
      it { expect(subject.first).to include('key' => 'value') }
      it do
        expect(subject.second).to eq(
          "typ" => "JWT",
          "alg" => "RS256",
          "kid" => "OGXY:4TR7:FAVO:WEM2:XXEW:E4FP:TKL7:7ACK:TZAF:D54P:SUIA:P3B2")
      end
    end

    context 'for invalid key to raise an exception' do
      let(:new_key) { OpenSSL::PKey::RSA.generate(512) }

      subject { JWT.decode(rsa_encoded, new_key, true, { algorithm: 'RS256' }) }

      it { expect {subject}.to raise_error(JWT::DecodeError) }
    end
  end
end
