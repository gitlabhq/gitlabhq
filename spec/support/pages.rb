# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, :http_pages_enabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_http).and_return(['1.1.1.1:80'])
  end

  config.before(:each, :https_pages_enabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_https).and_return(['1.1.1.1:443'])
  end

  config.before(:each, :http_pages_disabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_http).and_return(false)
  end

  config.before(:each, :https_pages_disabled) do |_|
    allow(Gitlab.config.pages).to receive(:external_https).and_return(false)
  end
end
