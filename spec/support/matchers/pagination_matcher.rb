# frozen_string_literal: true

RSpec::Matchers.define :include_pagination_headers do |expected|
  pagination_headers = %w[X-Total X-Total-Pages X-Per-Page X-Page X-Next-Page X-Prev-Page Link]

  match do |actual|
    expect(actual.headers).to include(*pagination_headers)
  end

  failure_message do |actual|
    missing = pagination_headers - actual.headers.keys
    "expected response to include pagination headers #{pagination_headers.inspect}, " \
      "but missing: #{missing.inspect}"
  end
end

RSpec::Matchers.define :include_limited_pagination_headers do |expected|
  limited_headers = %w[X-Per-Page X-Page X-Next-Page X-Prev-Page Link]

  match do |actual|
    expect(actual.headers).to include(*limited_headers)
  end

  failure_message do |actual|
    missing = limited_headers - actual.headers.keys
    "expected response to include limited pagination headers #{limited_headers.inspect}, " \
      "but missing: #{missing.inspect}"
  end
end

RSpec::Matchers.define :include_offset_url_params_in_next_link do |expected_page_number|
  include PaginationHelpers

  match do |actual|
    expect(actual.headers).to include('Link')

    params_for_next_page = pagination_params_from_next_url(actual)
    expect(params_for_next_page['page']).to eq(expected_page_number.to_s)
  end

  failure_message do |actual|
    if actual.headers['Link'].nil?
      "expected response to include 'Link' header, but it was missing"
    else
      params_for_next_page = pagination_params_from_next_url(actual)
      "expected next link to have page=#{expected_page_number}, " \
        "but got page=#{params_for_next_page['page'].inspect}"
    end
  end
end

RSpec::Matchers.define :include_keyset_url_params do |expected|
  include PaginationHelpers

  match do |actual|
    params_for_next_page = pagination_params_from_next_url(actual)

    expect(params_for_next_page).to include('cursor')
  end

  failure_message do |actual|
    params_for_next_page = pagination_params_from_next_url(actual)
    "expected next link to include 'cursor' param, but params were: #{params_for_next_page.keys.inspect}"
  end
end
