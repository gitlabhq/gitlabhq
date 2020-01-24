# frozen_string_literal: true

require Rails.root.join("spec/support/helpers/dns_helpers")

RSpec.configure do |config|
  config.include DnsHelpers

  config.before do
    block_dns!
  end

  config.before(:each, :permit_dns) do
    permit_dns!
  end

  config.before(:each, :stub_invalid_dns_only) do
    permit_dns!
    stub_invalid_dns!
  end
end
