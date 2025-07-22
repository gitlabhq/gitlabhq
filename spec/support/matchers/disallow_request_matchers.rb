# frozen_string_literal: true

module DisallowRequestMatchers
  extend RSpec::Matchers::DSL

  matcher :have_flash_message do |expected_message|
    match do |middleware|
      alert = middleware.env['rack.session'].to_hash
                        .dig('flash', 'flashes', 'alert')
      alert&.include?(expected_message)
    end
  end

  matcher :have_json_message do |expected_message|
    match do |response|
      response_body = Gitlab::Json.parse(response.body)

      response_body&.dig('message')&.include?(expected_message)
    end
  end

  matcher :disallow_request do
    match { |middleware| have_flash_message('You cannot perform write operations').matches?(middleware) }
  end

  matcher :disallow_request_in_json do
    match { |response| have_json_message('You cannot perform write operations').matches?(response) }
  end

  matcher :have_maintenance_mode_message do
    match do |middleware|
      have_flash_message('GitLab is undergoing maintenance').matches?(middleware)
    end
  end

  matcher :have_maintenance_mode_message_json do |custom_message|
    match do |response|
      have_json_message(custom_message || 'GitLab is undergoing maintenance').matches?(response)
    end
  end
end
