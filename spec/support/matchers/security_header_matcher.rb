# frozen_string_literal: true

RSpec::Matchers.define :include_security_headers do |expected|
  match do |actual|
    expect(actual.headers).to include('X-Content-Type-Options')
  end

  failure_message do |actual|
    "expected response to include 'X-Content-Type-Options' header, " \
      "but headers were: #{actual.headers.keys.inspect}"
  end
end
