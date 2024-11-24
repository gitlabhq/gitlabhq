# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect do
  describe '.signing_algorithm' do
    it 'returns the signing_algorithm as an uppercase symbol' do
      expect(subject.signing_algorithm).to eq :RS256
    end
  end

  describe '.signing_key' do
    it 'returns the private key as JWK instance' do
      expect(subject.signing_key).to be_a ::JWT::JWK::KeyBase
      expect(subject.signing_key.kid).to eq 'IqYwZo2cE6hsyhs48cU8QHH4GanKIx0S4Dc99kgTIMA'
    end
  end

  describe '.signing_key_normalized' do
    context 'when signing key is RSA' do
      it 'returns the RSA public key parameters' do
        expect(subject.signing_key_normalized).to eq(
          :kty => 'RSA',
          :kid => 'IqYwZo2cE6hsyhs48cU8QHH4GanKIx0S4Dc99kgTIMA',
          :e => 'AQAB',
          :n => 'sjdnSA6UWUQQHf6BLIkIEUhMRNBJC1NN_pFt1EJmEiI88GS0ceROO5B5Ooo9Y3QOWJ_n-u1uwTHBz0HCTN4wgArWd1TcqB5GQzQRP4eYnWyPfi4CfeqAHzQp-v4VwbcK0LW4FqtW5D0dtrFtI281FDxLhARzkhU2y7fuYhL8fVw5rUhE8uwvHRZ5CEZyxf7BSHxIvOZAAymhuzNLATt2DGkDInU1BmF75tEtBJAVLzWG_j4LPZh1EpSdfezqaXQlcy9PJi916UzTl0P7Yy-ulOdUsMlB6yo8qKTY1-AbZ5jzneHbGDU_O8QjYvii1WDmJ60t0jXicmOkGrOhruOptw'
        )
      end
    end

    context 'when signing key is EC' do
      before { configure_ec }

      it 'returns the EC public key parameters' do
        expect(subject.signing_key_normalized).to eq(
          :kty => 'EC',
          :kid => 'dOx_AhaepicN2r2M-sxZhgkYZMCX7dYhPsNOw1ZiFnI',
          :crv => 'P-521',
          :x => 'AeYVvbl3zZcFCdE-0msqOowYODjzeXAhjsZKhdNjGlDREvko3UFOw6S43g-s8bvVBmBz3fCodEzFRYQqJVI4UFvF',
          :y => 'AYJ7GYeBm_Fb6liN53xGASdbRSzF34h4BDSVYzjtQc7I-1LK17fwwS3VfQCJwaT6zX33HTrhR4VoUEUJHKwR3dNs'
        )
      end
    end

    context 'when signing key is HMAC' do
      before { configure_hmac }

      it 'returns the HMAC public key parameters' do
        expect(subject.signing_key_normalized).to eq(
          :kty => 'oct',
          :kid => 'lyAW7LdxryFWQtLdgxZpOrI87APHrzJKgWLT0BkWVog'
        )
      end
    end
  end

  describe 'registering grant flows' do
    describe Doorkeeper::Request do
      it 'uses the correct strategy for "id_token" response types' do
        expect(described_class.authorization_strategy('id_token')).to eq(Doorkeeper::Request::IdToken)
      end

      it 'uses the correct strategy for "id_token token" response types' do
        expect(described_class.authorization_strategy('id_token token')).to eq(Doorkeeper::Request::IdTokenToken)
      end
    end
  end
end
