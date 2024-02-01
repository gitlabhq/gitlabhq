require_relative "helper"
require "sidekiq/web"
require "rack/test"

class FilterJob
  include Sidekiq::Job

  def perform(a, b)
    a + b
  end
end

describe "filtering" do
  include Rack::Test::Methods

  before do
    @config = reset!
    app.middlewares.clear
  end

  def app
    Sidekiq::Web
  end

  it "finds jobs matching substring" do
    jid1 = FilterJob.perform_in(5, "bob", "tammy")
    jid2 = FilterJob.perform_in(5, "mike", "jim")

    get "/scheduled"
    assert_equal 200, last_response.status
    assert_match(/#{jid1}/, last_response.body)
    assert_match(/#{jid2}/, last_response.body)

    post "/filter/scheduled", substr: "tammy"
    assert_equal 200, last_response.status
    assert_match(/#{jid1}/, last_response.body)
    refute_match(/#{jid2}/, last_response.body)

    post "/filter/scheduled", substr: ""
    assert_equal 302, last_response.status
    get "/filter/scheduled"
    assert_equal 302, last_response.status
    get "/filter/retries"
    assert_equal 302, last_response.status
    get "/filter/dead"
    assert_equal 302, last_response.status
  end
end
