# frozen_string_literal: true
#
# Pairs with lib/gitlab/no_cache_headers.rb
#

RSpec.shared_examples 'uncached response' do
  it 'defines an uncached header response' do
    expect(response.headers["Cache-Control"]).to include("no-store", "no-cache")
    expect(response.headers["Pragma"]).to eq("no-cache")
    expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
  end
end
