# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OtpKeyRotator do
  let(:file) { Tempfile.new("otp-key-rotator-test") }
  let(:filename) { file.path }
  let(:old_key) { Gitlab::Application.credentials.otp_key_base }
  let(:new_key) { "00" * 32 }
  let!(:users) { create_list(:user, 5, :two_factor) }

  after do
    file.close
    file.unlink
  end

  def data
    CSV.read(filename)
  end

  def build_row(user, applied = false)
    [user.id.to_s, encrypt_otp(user, old_key), encrypt_otp(user, new_key)]
  end

  def encrypt_otp(user, key)
    opts = {
      value: user.otp_secret,
      iv: user.encrypted_otp_secret_iv.unpack("m").join,
      salt: user.encrypted_otp_secret_salt.unpack("m").join,
      algorithm: 'aes-256-cbc',
      insecure_mode: true,
      key: key
    }
    [Encryptor.encrypt(opts)].pack("m")
  end

  subject(:rotator) { described_class.new(filename) }

  describe '#rotate!' do
    subject(:rotation) { rotator.rotate!(old_key: old_key, new_key: new_key) }

    it 'stores the calculated values in a spreadsheet' do
      rotation

      expect(data).to match_array(users.map { |u| build_row(u) })
    end

    context 'new key is too short' do
      let(:new_key) { "00" * 31 }

      it { expect { rotation }.to raise_error(ArgumentError) }
    end

    context 'new key is the same as the old key' do
      let(:new_key) { old_key }

      it { expect { rotation }.to raise_error(ArgumentError) }
    end
  end

  describe '#rollback!' do
    it 'updates rows to the old value' do
      file.puts("#{users[0].id},old,new")
      file.close

      rotator.rollback!

      expect(users[0].reload.encrypted_otp_secret).to eq('old')
      expect(users[1].reload.encrypted_otp_secret).not_to eq('old')
    end
  end
end
