# frozen_string_literal: true

RSpec::Matchers.define :have_current_path_with_normalized_query do |expected_url, **options|
  expected_uri = Addressable::URI.parse(expected_url)
  expected_path = expected_uri.omit(:query).to_s

  match do |page|
    page.has_current_path?(expected_path, **options, ignore_query: true) do |uri|
      query_params(uri) == query_params(expected_uri)
    end
  end

  match_when_negated do |page|
    page.has_no_current_path?(expected_path, **options, ignore_query: true) do |uri|
      query_params(uri) == query_params(expected_uri)
    end
  end

  failure_message do |page|
    "expected current URL to equal #{expected_url.inspect} (normalizing query parameters), " \
      "but got #{page.current_url.inspect}"
  end

  failure_message_when_negated do |page|
    "expected current URL not to equal #{expected_url.inspect} (normalizing query parameters), " \
      "but got #{page.current_url.inspect}"
  end

  def query_params(uri)
    URI.decode_www_form(uri.query.to_s).group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
  end
end
