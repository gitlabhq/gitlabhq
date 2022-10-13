# frozen_string_literal: true

require 'spec_helper'
require 'active_model'

class TwoFactorBackupablePbkdf2Double
  extend ::ActiveModel::Callbacks
  include ::ActiveModel::Validations::Callbacks
  extend  ::Devise::Models

  # stub out the ::ActiveRecord::Encryption::EncryptableRecord API
  attr_accessor :otp_secret
  def self.encrypts(*attrs)
    nil
  end

  define_model_callbacks :update

  devise :two_factor_backupable, otp_number_of_backup_codes: 10
  devise :two_factor_backupable_pbkdf2

  attr_accessor :otp_backup_codes
end

module Gitlab
  class FIPS
    def enabled?
    end
  end
end

RSpec.describe ::Devise::Models::TwoFactorBackupablePbkdf2 do
  subject { TwoFactorBackupablePbkdf2Double.new }

  describe '#generate_otp_backup_codes_pbkdf2!' do
    context 'with no existing recovery codes' do
      before do
        @plaintext_codes = subject.generate_otp_backup_codes_pbkdf2!
      end

      it 'generates the correct number of new recovery codes' do
        expect(subject.otp_backup_codes.length).to eq(subject.class.otp_number_of_backup_codes)
      end

      it 'generates recovery codes of the correct length' do
        @plaintext_codes.each do |code|
          expect(code.length).to eq(subject.class.otp_backup_code_length)
        end
      end

      it 'generates distinct recovery codes' do
        expect(@plaintext_codes.uniq).to contain_exactly(*@plaintext_codes)
      end

      it 'stores the codes as pbkdf2 hashes' do
        subject.otp_backup_codes.each do |code|
          expect(code.start_with?("$pbkdf2-sha512$")).to be_truthy
        end
      end
    end
  end

  describe '#invalidate_otp_backup_code_pdkdf2!' do
    before do
      @plaintext_codes = subject.generate_otp_backup_codes_pbkdf2!
    end

    context 'given an invalid recovery code' do
      it 'returns false' do
        expect(subject.invalidate_otp_backup_code_pdkdf2!('password')).to be false
      end
    end

    context 'given a valid recovery code' do
      it 'returns true' do
        @plaintext_codes.each do |code|
          expect(subject.invalidate_otp_backup_code_pdkdf2!(code)).to be true
        end
      end

      it 'invalidates that recovery code' do
        code = @plaintext_codes.sample

        subject.invalidate_otp_backup_code_pdkdf2!(code)
        expect(subject.invalidate_otp_backup_code_pdkdf2!(code)).to be false
      end

      it 'does not invalidate the other recovery codes' do
        code = @plaintext_codes.sample
        subject.invalidate_otp_backup_code_pdkdf2!(code)

        @plaintext_codes.delete(code)

        @plaintext_codes.each do |code|
          expect(subject.invalidate_otp_backup_code_pdkdf2!(code)).to be true
        end
      end
    end
  end
end
