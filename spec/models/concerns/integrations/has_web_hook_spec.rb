# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HasWebHook, feature_category: :webhooks do
  let(:integration_class) do
    Class.new(Integration) do
      include Integrations::HasWebHook
    end
  end

  let(:integration) { integration_class.new }

  context 'when hook_url and url_variables are not implemented' do
    it { expect { integration.hook_url }.to raise_error(NotImplementedError) }
    it { expect { integration.url_variables }.to raise_error(NotImplementedError) }
  end

  context 'when integration does not respond to enable_ssl_verification' do
    it { expect(integration.hook_ssl_verification).to eq true }
  end

  context 'when integration responds to enable_ssl_verification' do
    let(:integration) { build(:drone_ci_integration, enable_ssl_verification: true) }

    it { expect(integration.hook_ssl_verification).to eq true }
  end
end
