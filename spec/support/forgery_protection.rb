# frozen_string_literal: true

module ForgeryProtection
  def with_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  module_function :with_forgery_protection
end

RSpec.configure do |config|
  config.around(:each, :allow_forgery_protection) do |example|
    ForgeryProtection.with_forgery_protection do
      example.call
    end
  end
end
