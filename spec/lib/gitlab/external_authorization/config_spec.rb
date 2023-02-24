# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExternalAuthorization::Config, feature_category: :system_access do
  it 'allows deploy tokens and keys when external authorization is disabled' do
    stub_application_setting(external_authorization_service_enabled: false)
    expect(described_class.allow_deploy_tokens_and_deploy_keys?).to be_eql(true)
  end

  context 'when external authorization is enabled' do
    it 'disable deploy tokens and keys' do
      stub_application_setting(external_authorization_service_enabled: true)
      expect(described_class.allow_deploy_tokens_and_deploy_keys?).to be_eql(false)
    end

    it "enable deploy tokens and keys when it is explicitly enabled and service url is blank" do
      stub_application_setting(external_authorization_service_enabled: true)
      stub_application_setting(allow_deploy_tokens_and_keys_with_external_authn: true)
      expect(described_class.allow_deploy_tokens_and_deploy_keys?).to be_eql(true)
    end
  end
end
