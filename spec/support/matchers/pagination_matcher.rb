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
