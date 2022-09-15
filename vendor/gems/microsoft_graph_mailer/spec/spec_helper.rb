# frozen_string_literal: true

require "rails"
require "action_mailer/railtie"

require "microsoft_graph_mailer"

require "mail"

require "webmock/rspec"

RSpec.configure do |config|
end

def fixture_path(*path)
  File.join(__dir__, "fixtures", path)
end

def stub_token_request(microsoft_graph_settings:, access_token:, response_status:)
  stub_request(
    :post,
    "#{microsoft_graph_settings[:azure_ad_endpoint]}/#{microsoft_graph_settings[:tenant]}/oauth2/v2.0/token"
  ).with(
    body: {
      "grant_type" => "client_credentials",
      "scope" => "#{microsoft_graph_settings[:graph_endpoint]}/.default"
    }
  ).to_return(
    body: {
      "token_type" => "Bearer",
      "expires_in" => "3599",
      "access_token" => access_token
    }.to_json,
    status: response_status,
    headers: { "content-type" => "application/json; charset=utf-8" }
  )
end

def stub_send_mail_request(microsoft_graph_settings:, access_token:, message:, response_status:)
  if message[:bcc]
    previous_message_bcc_include_in_headers = message[:bcc].include_in_headers
    message[:bcc].include_in_headers = true
  end

  stub_request(
    :post,
    "#{microsoft_graph_settings[:graph_endpoint]}/v1.0/users/#{microsoft_graph_settings[:user_id]}/sendMail"
  ).with(
    body: Base64.encode64(message.encoded),
    headers: {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "text/plain"
    }
  ).to_return(
    body: "",
    status: response_status
  )
ensure
  message[:bcc].include_in_headers = previous_message_bcc_include_in_headers if message[:bcc]
end
