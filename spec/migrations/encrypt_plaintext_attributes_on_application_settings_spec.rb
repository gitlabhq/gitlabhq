# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20191120115530_encrypt_plaintext_attributes_on_application_settings.rb')

describe EncryptPlaintextAttributesOnApplicationSettings, :migration do
  let(:migration) { described_class.new }
  let(:application_settings) { table(:application_settings) }
  let(:plaintext) { 'secret-token' }

  PLAINTEXT_ATTRIBUTES = %w[
    akismet_api_key
    elasticsearch_aws_secret_access_key
    recaptcha_private_key
    recaptcha_site_key
    slack_app_secret
    slack_app_verification_token
  ].freeze

  describe '#up' do
    it 'encrypts token and saves it' do
      application_setting = application_settings.create
      application_setting.update_columns(
        PLAINTEXT_ATTRIBUTES.each_with_object({}) do |plaintext_attribute, attributes|
          attributes[plaintext_attribute] = plaintext
        end
      )

      migration.up

      application_setting.reload
      PLAINTEXT_ATTRIBUTES.each do |plaintext_attribute|
        expect(application_setting[plaintext_attribute]).not_to be_nil
        expect(application_setting["encrypted_#{plaintext_attribute}"]).not_to be_nil
        expect(application_setting["encrypted_#{plaintext_attribute}_iv"]).not_to be_nil
      end
    end
  end

  describe '#down' do
    it 'decrypts encrypted token and saves it' do
      application_setting = application_settings.create(
        PLAINTEXT_ATTRIBUTES.each_with_object({}) do |plaintext_attribute, attributes|
          attributes[plaintext_attribute] = plaintext
        end
      )

      migration.down

      application_setting.reload
      PLAINTEXT_ATTRIBUTES.each do |plaintext_attribute|
        expect(application_setting[plaintext_attribute]).to eq(plaintext)
        expect(application_setting["encrypted_#{plaintext_attribute}"]).to be_nil
        expect(application_setting["encrypted_#{plaintext_attribute}_iv"]).to be_nil
      end
    end
  end
end
