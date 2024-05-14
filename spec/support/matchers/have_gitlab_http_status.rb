# frozen_string_literal: true

RSpec::Matchers.define :have_gitlab_http_status do |expected|
  match do |actual|
    expect(actual).to have_http_status(expected)
  end

  description do
    "respond with numeric status code #{expected}"
  end

  failure_message do |actual|
    # actual can be either an ActionDispatch::TestResponse (which uses #response_code)
    # or a Capybara::Session (which uses #status_code)
    response_code = actual.try(:response_code) || actual.try(:status_code)

    "expected the response to have status code #{expected.inspect} " \
    "but it was #{response_code}. The response was: #{actual.body}"
  end
end
