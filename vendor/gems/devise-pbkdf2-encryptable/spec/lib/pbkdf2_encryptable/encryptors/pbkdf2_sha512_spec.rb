# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512 do
  let(:bcrypt_hash) { '$2a$12$ftnD4XSrhVdlEaEgCn/lxO0Pt3QplwgblmhCug3nSeRhh5a9UDBWK' }
  let(:pbkdf2_sha512_hash) { '$pbkdf2-sha512$20000$boHGAw0hEyI$DBA67J7zNZebyzLtLk2X9wRDbmj1LNKVGnZLYyz6PGrIDGIl45fl/BPH0y1TPZnV90A20i.fD9C3G9Bp8jzzOA' }

  describe '.compare' do
    subject(:compare) { described_class.compare(encrypted_password, password) }

    context 'with a PBKDF2+SHA512 encrypted password' do
      let(:encrypted_password) { pbkdf2_sha512_hash }

      context 'with a matching password' do
        let(:password) { 'password' }

        it { is_expected.to eq(true) }
      end

      context 'with an incorrect password' do
        let(:password) { 'other_password' }

        it { is_expected.to eq(false) }
      end
    end

    context 'with a non PBKDF2+SHA512 encrypted password' do
      let(:encrypted_password) { bcrypt_hash }
      let(:password) { 'password' }

      it 'raises an invalid hash error ' do
        expect { compare }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash, 'invalid PBKDF2 hash'
      end
    end
  end

  describe '.digest' do
    it 'returns a properly formatted and correct hash' do
      expect(described_class.digest('password', 20000, '6e81c6030d211322')).to eq(pbkdf2_sha512_hash)
    end

    it 'raises an error if stretches is not greater than 0' do
      expect { described_class.digest('password', 0, '6e81c6030d211322') }
        .to raise_error('Stretches must be greater than zero')
    end
  end

  describe '.split_digest' do
    subject(:split_digest) { described_class.split_digest(digest) }

    context 'with a PBKDF2+SHA512 digest' do
      let(:digest) { pbkdf2_sha512_hash }

      it { is_expected.to eq({
          strategy: 'pbkdf2-sha512',
          stretches: 20000,
          salt: '6e81c6030d211322',
          checksum: '0c103aec9ef335979bcb32ed2e4d97f704436e68f52cd2951a764b632cfa3c6ac80c6225e397e5fc13c7d32d533d99d5f74036d22f9f0fd0b71bd069f23cf338'
        })
      }
    end

    context 'with a PBKDF2+SHA256 digest' do
      let(:digest) { '$pbkdf2-sha256$6400$.6UI/S.nXIk8jcbdHx3Fhg$98jZicV16ODfEsEZeYPGHU3kbrUrvUEXOPimVSQDD44' }

      it 'raises invalid hash error' do
        expect { split_digest }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash, 'invalid PBKDF2 SHA512 hash'
      end
    end

    context 'with a BCrypt digest' do
      let(:digest) { bcrypt_hash }

      it 'raises invalid hash error' do
        expect { split_digest }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash, 'invalid PBKDF2 hash'
      end
    end
  end
end
