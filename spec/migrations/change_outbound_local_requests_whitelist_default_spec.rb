# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeOutboundLocalRequestsWhitelistDefault do
  let(:application_settings) { table(:application_settings) }

  it 'defaults to empty array' do
    setting = application_settings.create!
    setting_with_value = application_settings.create!(outbound_local_requests_whitelist: '{a,b}')

    expect(application_settings.where(outbound_local_requests_whitelist: nil).count).to eq(1)

    migrate!

    expect(application_settings.where(outbound_local_requests_whitelist: nil).count).to eq(0)
    expect(setting.reload.outbound_local_requests_whitelist).to eq([])
    expect(setting_with_value.reload.outbound_local_requests_whitelist).to eq(%w[a b])
  end
end
