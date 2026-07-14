# frozen_string_literal: true

require 'spec_helper'

# Ensures the `<delivery_method>_settings` methods are available in the around hook
require 'aws-actionmailer-ses'
require 'microsoft_graph_mailer'

RSpec.describe 'mailer_delivery_method initializer for GitLab', feature_category: :notifications do
  let(:microsoft_graph_setting) do
    {
      user_id: SecureRandom.hex,
      tenant: SecureRandom.hex,
      client_id: SecureRandom.hex,
      client_secret: SecureRandom.hex,
      azure_ad_endpoint: 'https://test-azure_ad_endpoint',
      graph_endpoint: 'https://test-graph_endpoint'
    }
  end

  let(:amazon_ses_setting) do
    {
      region: 'us-east-1',
      access_key_id: nil,
      secret_access_key: nil,
      role_arn: nil
    }
  end

  def load_initializer
    load Rails.root.join('config/initializers/mailer_delivery_method.rb')
  end

  # Restore ActionMailer state mutated by loading the initializer.
  around do |example|
    previous_delivery_method = ActionMailer::Base.delivery_method
    previous_microsoft_graph_settings = ActionMailer::Base.microsoft_graph_settings
    previous_ses_v2_settings = ActionMailer::Base.ses_v2_settings

    example.run
  ensure
    ActionMailer::Base.delivery_method = previous_delivery_method
    ActionMailer::Base.microsoft_graph_settings = previous_microsoft_graph_settings
    ActionMailer::Base.ses_v2_settings = previous_ses_v2_settings
  end

  before do
    stub_microsoft_graph_mailer_setting(microsoft_graph_setting.merge(enabled: false))
    stub_amazon_ses_mailer_setting(amazon_ses_setting.merge(enabled: false))
  end

  context 'when neither provider is enabled' do
    it 'does not change the delivery method' do
      previous_delivery_method = ActionMailer::Base.delivery_method

      load_initializer

      expect(ActionMailer::Base.delivery_method).to eq(previous_delivery_method)
    end
  end

  context 'when microsoft_graph_mailer is enabled' do
    before do
      stub_microsoft_graph_mailer_setting(microsoft_graph_setting.merge(enabled: true))
    end

    it 'configures ActionMailer for Microsoft Graph', :aggregate_failures do
      load_initializer

      expect(ActionMailer::Base.delivery_method).to eq(:microsoft_graph)
      expect(ActionMailer::Base.microsoft_graph_settings).to eq(microsoft_graph_setting)
    end
  end

  context 'when amazon_ses_mailer is enabled' do
    let(:credentials) { instance_double(Aws::Credentials) }

    before do
      stub_amazon_ses_mailer_setting(
        amazon_ses_setting.merge(
          enabled: true,
          access_key_id: 'AKIAEXAMPLE',
          secret_access_key: 'secret',
          role_arn: 'arn:aws:iam::123456789012:role/ses-mailer'
        )
      )

      allow(Gitlab::Aws::CredentialsResolver).to receive(:resolve).and_return(credentials)
    end

    it 'configures ActionMailer for SES with resolved credentials', :aggregate_failures do
      load_initializer

      expect(Gitlab::Aws::CredentialsResolver).to have_received(:resolve).with(
        region: 'us-east-1',
        role_arn: 'arn:aws:iam::123456789012:role/ses-mailer',
        role_session_name: 'gitlab_amazon_ses_mailer',
        access_key_id: 'AKIAEXAMPLE',
        secret_access_key: 'secret'
      )
      expect(ActionMailer::Base.delivery_method).to eq(:ses_v2)
      expect(ActionMailer::Base.ses_v2_settings[:sesv2_client].config.region).to eq('us-east-1')
      expect(ActionMailer::Base.ses_v2_settings[:sesv2_client].config.credentials).to eq(credentials)
    end

    context 'when the resolver returns no credentials' do
      let(:credentials) { nil }

      it 'omits credentials from the SES settings', :aggregate_failures do
        load_initializer

        expect(ActionMailer::Base.delivery_method).to eq(:ses_v2)
        expect(ActionMailer::Base.ses_v2_settings[:sesv2_client].config.region).to eq('us-east-1')
        expect(ActionMailer::Base.ses_v2_settings[:sesv2_client].config.credentials).to be_nil
      end
    end
  end

  context 'when both providers are enabled' do
    before do
      stub_microsoft_graph_mailer_setting(microsoft_graph_setting.merge(enabled: true))
      stub_amazon_ses_mailer_setting(amazon_ses_setting.merge(enabled: true))
    end

    it 'raises an error' do
      expect { load_initializer }.to raise_error(
        /Only one of microsoft_graph_mailer or amazon_ses_mailer can be enabled/
      )
    end
  end
end
