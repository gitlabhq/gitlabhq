# frozen_string_literal: true

require 'spec_helper'
require 'active_model'

RSpec.describe Devise::Models::Pbkdf2Encryptable do
  let(:unconfigured_model) do
    Class.new do
      include ActiveModel::Model
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks
      extend Devise::Models

      define_model_callbacks :update, only: :after

      devise :database_authenticatable, :pbkdf2_encryptable

      attr_accessor :encrypted_password

      def initialize(encrypted_password: '')
        self.encrypted_password = encrypted_password
      end
    end
  end

  let(:bcrypt_configured_model) do
    Class.new(unconfigured_model) do
      devise :database_authenticatable, :pbkdf2_encryptable, encryptor: :bcrypt
    end
  end

  let(:unknown_configured_model) do
    Class.new(unconfigured_model) do
      devise :database_authenticatable, :pbkdf2_encryptable, encryptor: :sha512
    end
  end

  let(:configured_model) do
    Class.new(unconfigured_model) do
      devise :database_authenticatable, :pbkdf2_encryptable, encryptor: :pbkdf2_sha512
    end
  end

  let(:user) { configured_model.new }
  let(:pbkdf2_sha512_hash) { '$pbkdf2-sha512$20000$boHGAw0hEyI$DBA67J7zNZebyzLtLk2X9wRDbmj1LNKVGnZLYyz6PGrIDGIl45fl/BPH0y1TPZnV90A20i.fD9C3G9Bp8jzzOA' }

  describe '#valid_password?' do
    let(:user) { configured_model.new(encrypted_password: pbkdf2_sha512_hash) }

    it 'validates a correct password' do
      expect(user.valid_password?('password')).to eq(true)
    end

    it 'does not validate an incorrect password' do
      expect(user.valid_password?('other_password')).to eq(false)
    end
  end

  describe '#password=' do
    it 'sets the correct encrypted_password value', :aggregate_failures do
      expect(user.encrypted_password).to be_empty

      user.password = 'password'

      expect(user.encrypted_password).to start_with('$pbkdf2-sha512$')
    end

    it 'clears split digest memoization' do
      user.encrypted_password = '$pbkdf2-sha512$1000$boHGAw0hEyI$DBA67J7zNZebyzLtLk2X9wRDbmj1LNKVGnZLYyz6PGrIDGIl45fl/BPH0y1TPZnV90A20i.fD9C3G9Bp8jzzOA'

      expect(user.password_stretches).to eq(1_000)

      user.password = 'other_password'

      expect(user.password_stretches).to eq(20_000)
    end
  end

  describe 'password_* methods' do
    let(:user) { configured_model.new(encrypted_password: encrypted_password) }

    context 'with a PBKDF2+SHA512 encrypted password' do
      let(:encrypted_password) { pbkdf2_sha512_hash }

      it 'extracts the correct split hash values', :aggregate_failures do
        expect(Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512).to receive(:split_digest).once.and_call_original

        expect(user.password_strategy).to eq(:pbkdf2_sha512)
        expect(user.password_salt).to eq('6e81c6030d211322')
        expect(user.password_stretches).to eq(20_000)
        expect(user.password_checksum).to eq('0c103aec9ef335979bcb32ed2e4d97f704436e68f52cd2951a764b632cfa3c6ac80c6225e397e5fc13c7d32d533d99d5f74036d22f9f0fd0b71bd069f23cf338')
      end
    end

    context 'with a BCrypt encrypted password' do
      let(:encrypted_password) { '$2a$10$xLTxCKOa75IU4RQGqqOrTuZOgZdJEzfSzjG6ZSEi/C31TB/yLZYpi' }

      it 'raises errors', :aggregate_failures do
        expect { user.password_strategy }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash
        expect { user.password_salt }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash
        expect { user.password_stretches }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash
        expect { user.password_checksum }.to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash
      end
    end
  end

  describe '.encryptor_class' do
    it 'returns a class when configured' do
      expect(configured_model.encryptor_class).to eq(Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512)
    end

    it 'raises an error when unconfigured' do
      expect { unconfigured_model.encryptor_class }
        .to raise_error('You need to specify an :encryptor in Devise configuration in order to use :pbkdf2_encryptable')
    end

    it 'raises an error when BCrypt is configured' do
      expect { bcrypt_configured_model.encryptor_class }
        .to raise_error('In order to use bcrypt as encryptor, simply remove :pbkdf2_encryptable from your devise model')
    end

    it 'raises an error when a class cannot be found' do
      expect { unknown_configured_model.encryptor_class }
        .to raise_error("Configured encryptor 'sha512' could not be found for pbkdf2_encryptable")
    end
  end
end
