# frozen_string_literal: true

require 'spec_helper'
require_relative '../../config/initializers/doorkeeper_openid_connect_patch'

RSpec.describe 'doorkeeper_openid_connect_patch', feature_category: :integrations do
  describe '.signing_key' do
    let(:config) { Doorkeeper::OpenidConnect::Config.new }

    before do
      allow(config).to receive(:signing_key).and_return(key)
      allow(config).to receive(:signing_algorithm).and_return(algorithm)
      allow(Doorkeeper::OpenidConnect).to receive(:configuration).and_return(config)
    end

    context 'with RS256 algorithm' do
      let(:algorithm) { :RS256 }
      # Taken from https://github.com/doorkeeper-gem/doorkeeper-openid_connect/blob/01903c81a2b6237a3bf576ed45864f69ef20184e/spec/dummy/config/initializers/doorkeeper_openid_connect.rb#L6-L34
      let(:key) do
        <<~KEY
          -----BEGIN RSA PRIVATE KEY-----
          MIIEpgIBAAKCAQEAsjdnSA6UWUQQHf6BLIkIEUhMRNBJC1NN/pFt1EJmEiI88GS0
          ceROO5B5Ooo9Y3QOWJ/n+u1uwTHBz0HCTN4wgArWd1TcqB5GQzQRP4eYnWyPfi4C
          feqAHzQp+v4VwbcK0LW4FqtW5D0dtrFtI281FDxLhARzkhU2y7fuYhL8fVw5rUhE
          8uwvHRZ5CEZyxf7BSHxIvOZAAymhuzNLATt2DGkDInU1BmF75tEtBJAVLzWG/j4L
          PZh1EpSdfezqaXQlcy9PJi916UzTl0P7Yy+ulOdUsMlB6yo8qKTY1+AbZ5jzneHb
          GDU/O8QjYvii1WDmJ60t0jXicmOkGrOhruOptwIDAQABAoIBAQChYNwMeu9IugJi
          NsEf4+JDTBWMRpOuRrwcpfIvQAUPrKNEB90COPvCoju0j9OxCDmpdPtq1K/zD6xx
          khlw485FVAsKufSp4+g6GJ75yT6gZtq1JtKo1L06BFFzb7uh069eeP7+wB6JxPHw
          KlAqwxvsfADhxeolQUKCTMb3Vjv/Aw2cO/nn6RAOeftw2aDmFy8Xl+oTUtSxyib0
          YCdU9cK8MxsxDdmowwHp04xRTm/wfG5hLEn7HMz1PP86iP9BiFsCqTId9dxEUTS1
          K+VAt9FbxRAq5JlBocxUMHNxLigb94Ca2FOMR7F6l/tronLfHD801YoObF0fN9qW
          Cgw4aTO5AoGBAOR79hiZVM7/l1cBid7hKSeMWKUZ/nrwJsVfNpu1H9xt9uDu+79U
          mcGfM7pm7L2qCNGg7eeWBHq2CVg/XQacRNtcTlomFrw4tDXUkFN1hE56t1iaTs9m
          dN9IDr6jFgf6UaoOxxoPT9Q1ZtO46l043Nzrkoz8cBEBaBY20bUDwCYjAoGBAMet
          tt1ImGF1cx153KbOfjl8v54VYUVkmRNZTa1E821nL/EMpoONSqJmRVsX7grLyPL1
          QyZe245NOvn63YM0ng0rn2osoKsMVJwYBEYjHL61iF6dPtW5p8FIs7auRnC3NrG0
          XxHATZ4xhHD0iIn14iXh0XIhUVk+nGktHU1gbmVdAoGBANniwKdqqS6RHKBTDkgm
          Dhnxw6MGa+CO3VpA1xGboxuRHeoY3KfzpIC5MhojBsZDvQ8zWUwMio7+w2CNZEfm
          g99wYiOjyPCLXocrAssj+Rzh97AdzuQHf5Jh4/W2Dk9jTbdPSl02ltj2Z+2lnJFz
          pWNjnqimHrSI09rDQi5NulJjAoGBAImquujVpDmNQFCSNA7NTzlTSMk09FtjgCZW
          67cKUsqa2fLXRfZs84gD+s1TMks/NMxNTH6n57e0h3TSAOb04AM0kDQjkKJdXfhA
          lrHEg4z4m4yf3TJ9Tat09HJ+tRIBPzRFp0YVz23Btg4qifiUDdcQWdbWIb/l6vCY
          qhsu4O4BAoGBANbceYSDYRdT7a5QjJGibkC90Z3vFe4rDTBgZWg7xG0cpSU4JNg7
          SFR3PjWQyCg7aGGXiooCM38YQruACTj0IFub24MFRA4ZTXvrACvpsVokJlQiG0Z4
          tuQKYki41JvYqPobcq/rLE/AM7PKJftW35nqFuj0MrsUwPacaVwKBf5J
          -----END RSA PRIVATE KEY-----
        KEY
      end

      it 'returns the private key as JWK instance' do
        expect(Doorkeeper::OpenidConnect.signing_key).to be_a ::JWT::JWK::KeyBase
        expect(Doorkeeper::OpenidConnect.signing_key.kid).to eq 'IqYwZo2cE6hsyhs48cU8QHH4GanKIx0S4Dc99kgTIMA'
      end

      it 'matches json-jwt implementation' do
        json_jwt_key = OpenSSL::PKey::RSA.new(key).public_key.to_jwk.slice(:kty, :kid, :e, :n)
        expect(Doorkeeper::OpenidConnect.signing_key.export.sort.to_json).to eq(json_jwt_key.sort.to_json)
      end
    end

    context 'with HS512 algorithm' do
      let(:algorithm) { :HS512 }
      let(:key) { 'the_greatest_secret_key' }

      it 'returns the HMAC public key parameters' do
        expect(Doorkeeper::OpenidConnect.signing_key_normalized).to eq(
          kty: 'oct',
          kid: 'lyAW7LdxryFWQtLdgxZpOrI87APHrzJKgWLT0BkWVog'
        )
      end
    end
  end
end
