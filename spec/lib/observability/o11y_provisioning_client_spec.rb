# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Observability::O11yProvisioningClient, feature_category: :observability do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:client) { described_class.new }

  before do
    stub_request(:post, described_class::PROVISIONER_API)
      .to_return(status: 200, body: '{"status": "success"}')
  end

  describe '#provision_group' do
    subject(:provision_group) { client.provision_group(group, user) }

    context 'when API call is successful' do
      it 'returns success with settings params' do
        result = provision_group

        expect(result[:success]).to be true
        expect(result[:settings_params]).to include(
          o11y_service_name: group.id.to_s,
          o11y_service_user_email: user.email,
          o11y_service_password: be_present
        )
      end

      it 'makes an API request to the provisioner service' do
        provision_group

        expect(WebMock).to have_requested(:post, described_class::PROVISIONER_API)
          .with(
            body: hash_including(
              'o11y_provision_request' => hash_including(
                'group_id' => group.id,
                'email' => user.email,
                'user_name' => user.name,
                'group_path' => group.full_path
              )
            ),
            headers: {
              'Content-Type' => 'application/json',
              'User-Agent' => "GitLab/#{Gitlab::VERSION}",
              'X-API-Key' => described_class::DEFAULT_API_KEY
            }
          )
      end
    end

    context 'when API call fails' do
      before do
        stub_request(:post, described_class::PROVISIONER_API)
          .to_return(status: 500, body: '{"error": "Internal server error"}')
      end

      it 'returns failure with error message' do
        result = provision_group

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API call failed for observability group setting')
      end
    end

    context 'when API call raises an exception' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(SocketError.new('Network error'))
      end

      it 'returns failure with error message' do
        result = provision_group

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API call failed for observability group setting')
      end
    end
  end

  describe '#api_key' do
    subject(:api_key) { client.send(:api_key) }

    context 'when in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      context 'with production group setting' do
        let!(:production_setting) do
          create(:observability_group_o11y_setting,
            group: create(:group, id: described_class::PRODUCTION_GROUP_ID),
            o11y_service_post_message_encryption_key: 'production-secret-key')
        end

        it { is_expected.to eq('production-secret-key') }
      end

      context 'without production group setting' do
        it { is_expected.to be_nil }
      end
    end

    context 'when not in production environment' do
      before do
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it { is_expected.to eq(described_class::DEFAULT_API_KEY) }
    end
  end

  describe '#production_api_key' do
    subject(:production_api_key) { client.send(:production_api_key) }

    context 'with production group setting' do
      let!(:production_setting) do
        create(:observability_group_o11y_setting,
          group: create(:group, id: described_class::PRODUCTION_GROUP_ID),
          o11y_service_post_message_encryption_key: 'production-secret-key')
      end

      it { is_expected.to eq('production-secret-key') }
    end

    context 'without production group setting' do
      it { is_expected.to be_nil }
    end

    context 'with other group settings' do
      before do
        create(:observability_group_o11y_setting,
          group: create(:group),
          o11y_service_post_message_encryption_key: 'other-secret-key')
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'security' do
    let(:sensitive_fields) do
      {
        'o11y_service_password' => /[a-f0-9]{32}/,
        'o11y_service_post_message_encryption_key' => /[a-f0-9]{64}/,
        'encryption_key' => /[a-f0-9]{32}/,
        'password' => /[a-f0-9]{32}/
      }
    end

    context 'when API call raises an exception' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(SocketError.new('Network error'))
      end

      it 'does not include sensitive field names or patterns in error messages' do
        result = client.provision_group(group, user)

        sensitive_fields.each do |field_name, pattern|
          expect(result[:error]).not_to include(field_name)
          expect(result[:error]).not_to match(pattern)
        end
      end

      it 'logs API responses without filtering sensitive data' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: be_a(String),
            group_id: group.id
          )
        )

        client.provision_group(group, user)
      end
    end

    context 'when API call raises Gitlab::HTTP_V2::BlockedUrlError with sensitive data' do
      let(:sensitive_url) { 'https://user:secretpassword@blocked-domain.com/api' }
      let(:blocked_url_error) { Gitlab::HTTP_V2::BlockedUrlError.new("URL is blocked: #{sensitive_url}") }

      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(blocked_url_error)
      end

      it 'sanitizes sensitive data in the error message when logging' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: 'API request error for observability setting',
            group_id: group.id,
            error: 'URL is blocked: https://*****:*****@blocked-domain.com/api',
            error_class: 'Gitlab::HTTP_V2::BlockedUrlError'
          )
        )

        client.provision_group(group, user)
      end

      it 'does not include sensitive data in the returned error message' do
        result = client.provision_group(group, user)

        expect(result[:success]).to be false
        expect(result[:error]).to eq('API call failed for observability group setting')
        expect(result[:error]).not_to include('secretpassword')
        expect(result[:error]).not_to include('user:')
      end
    end
  end
end
