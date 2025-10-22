# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::GroupO11ySetting, feature_category: :observability do
  let_it_be(:group) { create(:group) }

  describe 'relations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    subject(:group_o11y_setting) { build(:observability_group_o11y_setting, group: group) }

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
        expect(group_o11y_setting.errors[:o11y_service_user_email]).to include(I18n.t(:invalid,
          scope: 'activerecord.errors.messages'))
      end
    end

    context 'when url is invalid' do
      [nil, ''].each do |invalid_url|
        it "is invalid with #{invalid_url}" do
          group_o11y_setting.o11y_service_url = invalid_url
          expect(group_o11y_setting).to be_invalid
          expect(group_o11y_setting.errors[:o11y_service_url]).to include("is invalid")
        end
      end

      it 'is invalid with malformed url' do
        group_o11y_setting.o11y_service_url = 'not-a-valid-url'
        expect(group_o11y_setting).to be_invalid
        expect(group_o11y_setting.errors[:o11y_service_url]).to include(
          "is blocked: Only allowed schemes are http, https"
        )
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

  describe '.find_by_group_id' do
    let_it_be(:group1) { create(:group) }
    let_it_be(:group2) { create(:group) }
    let_it_be(:setting1) { create(:observability_group_o11y_setting, group: group1) }
    let_it_be(:setting2) { create(:observability_group_o11y_setting, group: group2) }

    it 'finds the setting by group_id' do
      result = described_class.find_by_group_id(group1.id)
      expect(result).to eq(setting1)
    end

    it 'returns nil when no setting exists for the group_id' do
      non_existing_group_id = non_existing_record_id
      result = described_class.find_by_group_id(non_existing_group_id)
      expect(result).to be_nil
    end

    it 'finds the correct setting when multiple settings exist' do
      result = described_class.find_by_group_id(group2.id)
      expect(result).to eq(setting2)
    end
  end

  describe '#within_provisioning_window?' do
    let(:setting) { build(:observability_group_o11y_setting, group: group) }

    context 'when record is not persisted' do
      it 'returns false' do
        expect(setting.within_provisioning_window?).to be false
      end
    end

    context 'when record is persisted' do
      before do
        setting.save!
      end

      shared_examples 'returns true within window' do |time_offset|
        it "returns true at #{time_offset}" do
          travel_to(setting.created_at + time_offset) do
            expect(setting.within_provisioning_window?).to be true
          end
        end
      end

      shared_examples 'returns false outside window' do |time_offset|
        it "returns false at #{time_offset}" do
          travel_to(setting.created_at + time_offset) do
            expect(setting.within_provisioning_window?).to be false
          end
        end
      end

      include_examples 'returns true within window', 0.seconds
      include_examples 'returns true within window', 2.minutes + 30.seconds
      include_examples 'returns true within window', 5.minutes

      include_examples 'returns false outside window', 5.minutes + 1.second
      include_examples 'returns false outside window', 1.hour

      it 'returns true when current time is before creation' do
        travel_to(setting.created_at - 1.second) do
          expect(setting.within_provisioning_window?).to be true
        end
      end
    end
  end

  describe 'otel endpoints' do
    let(:setting) { build(:observability_group_o11y_setting, group: group) }

    shared_examples 'otel endpoint' do |method, port|
      context "when o11y_service_name is set" do
        before do
          setting.o11y_service_name = 'my-service'
        end

        it "returns the correct #{method} endpoint" do
          expect(setting.send(method)).to eq("http://my-service.otel.gitlab-o11y.com:#{port}")
        end
      end

      context "when o11y_service_name is nil" do
        before do
          setting.o11y_service_name = nil
          allow(setting).to receive(:name_from_url).and_return('service-from-url')
        end

        it "uses name_from_url as fallback" do
          expect(setting.send(method)).to eq("http://service-from-url.otel.gitlab-o11y.com:#{port}")
        end
      end

      context "when both o11y_service_name and name_from_url are nil" do
        before do
          setting.o11y_service_name = nil
          allow(setting).to receive_messages(name_from_url: nil, name_from_group: 'group-path')
        end

        it "uses name_from_group as fallback" do
          expect(setting.send(method)).to eq("http://group-path.otel.gitlab-o11y.com:#{port}")
        end
      end

      context "with special characters in service name" do
        before do
          setting.o11y_service_name = 'my-service-with-dashes'
        end

        it "handles service names with special characters" do
          expect(setting.send(method)).to eq("http://my-service-with-dashes.otel.gitlab-o11y.com:#{port}")
        end
      end
    end

    describe '#otel_http_endpoint' do
      include_examples 'otel endpoint', :otel_http_endpoint, 4318
    end

    describe '#otel_grpc_endpoint' do
      include_examples 'otel endpoint', :otel_grpc_endpoint, 4317
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
