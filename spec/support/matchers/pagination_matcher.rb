# frozen_string_literal: true

RSpec::Matchers.define :include_pagination_headers do |expected|
  match do |actual|
    expect(actual.headers).to include('X-Total', 'X-Total-Pages', 'X-Per-Page', 'X-Page', 'X-Next-Page', 'X-Prev-Page', 'Link')
  end
end

RSpec::Matchers.define :include_limited_pagination_headers do |expected|
  match do |actual|
    expect(actual.headers).to include('X-Per-Page', 'X-Page', 'X-Next-Page', 'X-Prev-Page', 'Link')
  end
end

RSpec::Matchers.define :include_offset_url_params_in_next_link do |expected_page_number|
  include PaginationHelpers

  match do |actual|
    expect(actual.headers).to include('Link')

    params_for_next_page = pagination_params_from_next_url(actual)
    expect(params_for_next_page['page']).to eq(expected_page_number.to_s)
  end
end

RSpec::Matchers.define :include_keyset_url_params do |expected|
  include PaginationHelpers

  match do |actual|
    params_for_next_page = pagination_params_from_next_url(actual)

    expect(params_for_next_page).to include('cursor')
  end
end
