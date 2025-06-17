# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :http_pages_enabled) do |_|
    allow(Gitlab.config.pages).to receive_messages(external_http: ['1.1.1.1:80'], custom_domain_mode: "http")
  end

  config.before(:each, :https_pages_enabled) do |_|
    allow(Gitlab.config.pages).to receive_messages(external_https: ['1.1.1.1:443'], custom_domain_mode: "https")
  end

  config.before(:each, :http_pages_disabled) do |_|
    allow(Gitlab.config.pages).to receive_messages(external_http: false, custom_domain_mode: nil)
  end

  config.before(:each, :https_pages_disabled) do |_|
    allow(Gitlab.config.pages).to receive_messages(external_https: false, custom_domain_mode: nil)
  end
end
