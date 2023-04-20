# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDesk::CustomEmailCredential, feature_category: :service_desk do
  let(:project) { build_stubbed(:project) }
  let(:credential) { build_stubbed(:service_desk_custom_email_credential, project: project) }
  let(:smtp_username) { "user@example.com" }
  let(:smtp_password) { "supersecret" }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    it { is_expected.to validate_presence_of(:smtp_address) }
    it { is_expected.to validate_length_of(:smtp_address).is_at_most(255) }
    it { is_expected.to allow_value('smtp.gmail.com').for(:smtp_address) }
    it { is_expected.to allow_value('1.1.1.1').for(:smtp_address) }
    it { is_expected.to allow_value('199.1.1.1').for(:smtp_address) }
    it { is_expected.not_to allow_value('https://example.com').for(:smtp_address) }
    it { is_expected.not_to allow_value('file://example').for(:smtp_address) }
    it { is_expected.not_to allow_value('/example').for(:smtp_address) }
    it { is_expected.not_to allow_value('localhost').for(:smtp_address) }
    it { is_expected.not_to allow_value('127.0.0.1').for(:smtp_address) }
    it { is_expected.not_to allow_value('192.168.12.12').for(:smtp_address) } # disallow local network

    it { is_expected.to validate_presence_of(:smtp_port) }
    it { is_expected.to validate_numericality_of(:smtp_port).only_integer.is_greater_than(0) }

    it { is_expected.to validate_presence_of(:smtp_username) }
    it { is_expected.to validate_length_of(:smtp_username).is_at_most(255) }

    it { is_expected.to validate_presence_of(:smtp_password) }
    it { is_expected.to validate_length_of(:smtp_password).is_at_least(8).is_at_most(128) }
  end

  describe 'encrypted #smtp_username' do
    subject { build_stubbed(:service_desk_custom_email_credential, smtp_username: smtp_username) }

    it 'saves and retrieves the encrypted smtp username and iv correctly' do
      expect(subject.encrypted_smtp_username).not_to be_nil
      expect(subject.encrypted_smtp_username_iv).not_to be_nil

      expect(subject.smtp_username).to eq(smtp_username)
    end
  end

  describe 'encrypted #smtp_password' do
    subject { build_stubbed(:service_desk_custom_email_credential, smtp_password: smtp_password) }

    it 'saves and retrieves the encrypted smtp password and iv correctly' do
      expect(subject.encrypted_smtp_password).not_to be_nil
      expect(subject.encrypted_smtp_password_iv).not_to be_nil

      expect(subject.smtp_password).to eq(smtp_password)
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }

    it 'can access service desk setting from project' do
      setting = build_stubbed(:service_desk_setting, project: project)

      expect(credential.service_desk_setting).to eq(setting)
    end
  end
end
