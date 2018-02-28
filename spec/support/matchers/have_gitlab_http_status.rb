RSpec::Matchers.define :have_gitlab_http_status do |expected|
  match do |actual|
    expect(actual).to have_http_status(expected)
  end

  description do
    "respond with numeric status code #{expected}"
  end

  failure_message do |actual|
    "expected the response to have status code #{expected.inspect}" \
    " but it was #{actual.response_code}. The response was: #{actual.body}"
  end
end
