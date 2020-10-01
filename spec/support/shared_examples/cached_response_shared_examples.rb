# frozen_string_literal: true
#
# Negates lib/gitlab/no_cache_headers.rb
#

RSpec.shared_examples 'cached response' do
  it 'defines a cached header response' do
    expect(response.headers["Cache-Control"]).not_to include("no-store", "no-cache")
    expect(response.headers["Pragma"]).not_to eq("no-cache")
    expect(response.headers["Expires"]).not_to eq("Fri, 01 Jan 1990 00:00:00 GMT")
  end
end
