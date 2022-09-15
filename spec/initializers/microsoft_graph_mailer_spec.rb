# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'microsoft_graph_mailer initializer for GitLab' do
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

  def load_microsoft_graph_mailer_initializer
    load Rails.root.join('config/initializers/microsoft_graph_mailer.rb')
  end

  context 'when microsoft_graph_mailer is enabled' do
    before do
      stub_microsoft_graph_mailer_setting(microsoft_graph_setting.merge(enabled: true))
    end

    it 'configures ActionMailer' do
      previous_delivery_method = ActionMailer::Base.delivery_method
      previous_microsoft_graph_settings = ActionMailer::Base.microsoft_graph_settings

      load_microsoft_graph_mailer_initializer

      expect(ActionMailer::Base.delivery_method).to eq(:microsoft_graph)
      expect(ActionMailer::Base.microsoft_graph_settings).to eq(microsoft_graph_setting)
    ensure
      ActionMailer::Base.delivery_method = previous_delivery_method
      ActionMailer::Base.microsoft_graph_settings = previous_microsoft_graph_settings
    end
  end

  context 'when microsoft_graph_mailer is disabled' do
    before do
      stub_microsoft_graph_mailer_setting(microsoft_graph_setting.merge(enabled: false))
    end

    it 'does not configure ActionMailer' do
      previous_delivery_method = ActionMailer::Base.delivery_method
      previous_microsoft_graph_settings = ActionMailer::Base.microsoft_graph_settings

      load_microsoft_graph_mailer_initializer

      expect(previous_microsoft_graph_settings).not_to eq(:microsoft_graph)
      expect(ActionMailer::Base.delivery_method).to eq(previous_delivery_method)
      expect(ActionMailer::Base.microsoft_graph_settings).to eq(previous_microsoft_graph_settings)
    end
  end
end
