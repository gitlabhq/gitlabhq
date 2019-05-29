require 'spec_helper'
require Rails.root.join('db', 'migrate', '20190524062810_generate_lets_encrypt_private_key.rb')

describe GenerateLetsEncryptPrivateKey, :migration do
  describe '#up' do
    let(:applications_settings) { table(:applications_settings) }

    it 'generates RSA private key and saves it in application settings' do
      application_setting = described_class::ApplicationSetting.create!

      described_class.new.up
      application_setting.reload

      expect(application_setting.lets_encrypt_private_key).to be_present
      expect do
        OpenSSL::PKey::RSA.new(application_setting.lets_encrypt_private_key)
      end.not_to raise_error
    end
  end
end
