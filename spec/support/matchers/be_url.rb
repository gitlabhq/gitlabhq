# frozen_string_literal: true

# Assert that this value is a valid URL of at least one type.
#
# By default, this checks that the URL is either a HTTP or HTTPS URI,
# but you can check other URI schemes by passing the type, eg:
#
# ```
# expect(value).to be_url(URI::FTP)
# ```
#
# Pass an empty array of types if you want to match any URI scheme (be
# aware that this might not do what you think it does! `foo` is a valid
# URI, for instance).
RSpec::Matchers.define :be_url do |types = [URI::HTTP, URI::HTTPS]|
  match do |actual|
    next false unless actual.present?

    uri = URI.parse(actual)
    Array.wrap(types).any? { |t| uri.is_a?(t) }
  rescue URI::InvalidURIError
    false
  end
end

# looks better when used like:
#   expect(thing).to receive(:method).with(a_valid_url)
RSpec::Matchers.alias_matcher :a_valid_url, :be_url
RSpec::Matchers.alias_matcher :be_http_url, :be_url
