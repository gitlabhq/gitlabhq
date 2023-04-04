# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::GooglePlay, feature_category: :mobile_devops do
  describe 'Validations' do
    context 'when active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :service_account_key_file_name }
      it { is_expected.to validate_presence_of :service_account_key }
      it { is_expected.to validate_presence_of :package_name }
      it { is_expected.to allow_value(File.read('spec/fixtures/service_account.json')).for(:service_account_key) }
      it { is_expected.not_to allow_value(File.read('spec/fixtures/group.json')).for(:service_account_key) }
      it { is_expected.to allow_value('com.example.myapp').for(:package_name) }
      it { is_expected.to allow_value('com.example.myorg.myapp').for(:package_name) }
      it { is_expected.to allow_value('com_us.example.my_org.my_app').for(:package_name) }
      it { is_expected.to allow_value('a.a.a').for(:package_name) }
      it { is_expected.to allow_value('com.example').for(:package_name) }
      it { is_expected.not_to allow_value('com').for(:package_name) }
      it { is_expected.not_to allow_value('com.example.my app').for(:package_name) }
      it { is_expected.not_to allow_value('1com.example.myapp').for(:package_name) }
      it { is_expected.not_to allow_value('com.1example.myapp').for(:package_name) }
      it { is_expected.not_to allow_value('com.example._myapp').for(:package_name) }
    end
  end

  context 'when integration is enabled' do
    let(:google_play_integration) { build(:google_play_integration) }

    describe '#fields' do
      it 'returns custom fields' do
        expect(google_play_integration.fields.pluck(:name)).to match_array(%w[package_name service_account_key
          service_account_key_file_name])
      end
    end

    describe '#test' do
      it 'returns true for a successful request' do
        allow_next_instance_of(Google::Apis::AndroidpublisherV3::AndroidPublisherService) do |instance|
          allow(instance).to receive(:list_reviews)
        end
        expect(google_play_integration.test[:success]).to be true
      end

      it 'returns false for an invalid request' do
        allow_next_instance_of(Google::Apis::AndroidpublisherV3::AndroidPublisherService) do |instance|
          allow(instance).to receive(:list_reviews).and_raise(Google::Apis::ClientError.new('error'))
        end
        expect(google_play_integration.test[:success]).to be false
      end
    end

    describe '#help' do
      it 'renders prompt information' do
        expect(google_play_integration.help).not_to be_empty
      end
    end

    describe '.to_param' do
      it 'returns the name of the integration' do
        expect(described_class.to_param).to eq('google_play')
      end
    end

    describe '#ci_variables' do
      let(:google_play_integration) { build_stubbed(:google_play_integration) }

      it 'returns vars when the integration is activated' do
        ci_vars = [
          {
            key: 'SUPPLY_PACKAGE_NAME',
            value: google_play_integration.package_name,
            masked: false,
            public: false
          },
          {
            key: 'SUPPLY_JSON_KEY_DATA',
            value: google_play_integration.service_account_key,
            masked: true,
            public: false
          }
        ]

        expect(google_play_integration.ci_variables).to match_array(ci_vars)
      end
    end
  end

  context 'when integration is disabled' do
    let(:google_play_integration) { build_stubbed(:google_play_integration, active: false) }

    describe '#ci_variables' do
      it 'returns an empty array' do
        expect(google_play_integration.ci_variables).to match_array([])
      end
    end
  end
end
