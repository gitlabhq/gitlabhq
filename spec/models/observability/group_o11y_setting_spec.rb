# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::GroupO11ySetting, feature_category: :observability do
  let_it_be(:group) { create(:group) }

  describe 'relations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    subject(:group_o11y_setting) { build(:observability_group_o11y_setting, group: group) }

    it { is_expected.to validate_presence_of(:o11y_service_user_email) }
    it { is_expected.to validate_presence_of(:o11y_service_password) }
    it { is_expected.to validate_presence_of(:o11y_service_post_message_encryption_key) }
    it { is_expected.to validate_presence_of(:o11y_service_url) }
    it { is_expected.to validate_length_of(:o11y_service_url).is_at_most(255) }
    it { is_expected.to validate_length_of(:o11y_service_password).is_at_most(510) }
    it { is_expected.to validate_length_of(:o11y_service_post_message_encryption_key).is_at_most(510) }

    context 'when email is invalid' do
      it 'is invalid with malformed email' do
        group_o11y_setting.o11y_service_user_email = 'invalid-email'
        expect(group_o11y_setting).to be_invalid
        expect(group_o11y_setting.errors[:o11y_service_user_email]).to include(I18n.t(:invalid,
          scope: 'valid_email.validations.email'))
      end

      it 'is invalid with empty email' do
        group_o11y_setting.o11y_service_user_email = ''
        expect(group_o11y_setting).to be_invalid
        expect(group_o11y_setting.errors[:o11y_service_user_email]).to include("can't be blank")
      end
    end

    context 'when url is invalid' do
      [nil, ''].each do |invalid_url|
        it "is invalid with #{invalid_url}" do
          group_o11y_setting.o11y_service_url = invalid_url
          expect(group_o11y_setting).to be_invalid
          expect(group_o11y_setting.errors[:o11y_service_url]).to include("can't be blank")
        end
      end

      it 'is invalid with malformed url' do
        group_o11y_setting.o11y_service_url = 'not-a-valid-url'
        expect(group_o11y_setting).to be_invalid
        expect(group_o11y_setting.errors[:o11y_service_url]).to be_present
      end

      it 'is invalid with url exceeding maximum length' do
        group_o11y_setting.o11y_service_url = "https://example.com/#{'a' * 256}"
        expect(group_o11y_setting).to be_invalid
        expect(group_o11y_setting.errors[:o11y_service_url]).to include('is too long (maximum is 255 characters)')
      end
    end

    context 'when url is valid' do
      [
        'http://example.com',
        'https://example.com',
        'https://example.com/api/v1',
        'https://example.com:8080',
        'http://localhost:3000/api'
      ].each do |valid_url|
        it "is valid with #{valid_url}" do
          group_o11y_setting.o11y_service_url = valid_url

          expect(group_o11y_setting).to be_valid
        end
      end
    end

    %i[o11y_service_password o11y_service_post_message_encryption_key].each do |field|
      context "when #{field} is too long" do
        it "is invalid with #{field} exceeding maximum length" do
          group_o11y_setting.send(:"#{field}=", 'a' * 511)
          expect(group_o11y_setting).to be_invalid
          expect(group_o11y_setting.errors[field]).to include('is too long (maximum is 510 characters)')
        end
      end
    end
  end

  describe 'encryption' do
    let(:password_value) { 'super-secret-password' }
    let(:secret_key_value) { 'super-secret-key' }
    let(:setting) do
      create(:observability_group_o11y_setting, o11y_service_password: password_value,
        o11y_service_post_message_encryption_key: secret_key_value).tap(&:reload)
    end

    shared_examples 'encrypts field' do |field_name, field_value|
      it "encrypts the #{field_name} value" do
        encrypted_value = setting.read_attribute_before_type_cast(field_name)

        expect(setting.send(field_name)).to eq(field_value)
        expect(encrypted_value).not_to eq(setting.send(field_name))
        expect(encrypted_value).not_to include(field_value)
      end
    end

    context 'when password encryption' do
      include_examples 'encrypts field', :o11y_service_password, 'super-secret-password'
    end

    context 'when secret_key encryption' do
      include_examples 'encrypts field', :o11y_service_post_message_encryption_key, 'super-secret-key'
    end

    context 'when updating encrypted fields' do
      let(:new_password) { 'new-super-secret-password' }
      let(:new_secret_key) { 'new-super-secret-key' }

      shared_examples 're-encrypts field when changed' do |field_name, new_value|
        it "re-encrypts #{field_name} when changed" do
          original_raw_value = setting.attributes[field_name.to_s]
          setting.send(:"#{field_name}=", new_value)
          setting.save!

          new_raw_value = setting.attributes[field_name.to_s]
          expect(new_raw_value).not_to eq(original_raw_value)
          expect(setting.send(field_name)).to eq(new_value)
        end
      end

      include_examples 're-encrypts field when changed', :o11y_service_password, 'new-super-secret-password'
      include_examples 're-encrypts field when changed', :o11y_service_post_message_encryption_key,
        'new-super-secret-key'
    end
  end

  describe 'factory' do
    it 'creates a valid record' do
      setting = build(:observability_group_o11y_setting)
      expect(setting).to be_valid
    end

    it 'associates with a group' do
      setting = create(:observability_group_o11y_setting)
      expect(setting.group).to be_present
    end
  end
end
