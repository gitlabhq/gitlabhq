# frozen_string_literal: true

RSpec::Matchers.define :disallow_request do
  match do |middleware|
    alert = middleware.env['rack.session'].to_hash
      .dig('flash', 'flashes', 'alert')

    alert&.include?('You cannot perform write operations')
  end
end

RSpec::Matchers.define :disallow_request_in_json do
  match do |response|
    json_response = Gitlab::Json.parse(response.body)
    response.body.include?('You cannot perform write operations') && json_response.key?('message')
  end
end
