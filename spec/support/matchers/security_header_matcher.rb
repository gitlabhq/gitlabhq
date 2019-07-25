# frozen_string_literal: true

RSpec::Matchers.define :include_security_headers do |expected|
  match do |actual|
    expect(actual.headers).to include('X-Content-Type-Options')
  end
end
