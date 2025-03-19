# frozen_string_literal: true

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

  it "finds retries matching substring" do
    add_retry("jid123", "mike")
    add_retry("jid456", "jim")

    get "/retries", substr: ""
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "jid123")
    assert_includes(last_response.body, "jid456")

    get "/retries", substr: "mike"
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "jid123")
    refute_includes(last_response.body, "jid456")
  end

  it "finds scheduled jobs matching substring" do
    jid1 = FilterJob.perform_in(5, "bob", "tammy")
    jid2 = FilterJob.perform_in(5, "mike", "jim")

    get "/scheduled", substr: ""
    assert_equal 200, last_response.status
    assert_match(/#{jid1}/, last_response.body)
    assert_match(/#{jid2}/, last_response.body)

    get "/scheduled", substr: "tammy"
    assert_equal 200, last_response.status
    assert_match(/#{jid1}/, last_response.body)
    refute_match(/#{jid2}/, last_response.body)
  end

  it "finds dead jobs matching substring" do
    add_dead("jid123", "mike")
    add_dead("jid456", "jim")

    get "/morgue", substr: ""
    assert_equal 200, last_response.status
    assert_includes(last_response.body, "jid123")
    assert_includes(last_response.body, "jid456")

    get "/morgue", substr: "jim"
    assert_equal 200, last_response.status
    refute_includes(last_response.body, "jid123")
    assert_includes(last_response.body, "jid456")
  end

  private

  def add_retry(*args)
    add_to_set("retry", *args)
  end

  def add_dead(*args)
    add_to_set("dead", *args)
  end

  def add_to_set(set, jid, arg)
    msg = {"class" => "FilterJob", "args" => [arg], "queue" => "default", "jid" => jid}
    @config.redis do |conn|
      conn.zadd(set, Time.now.to_f, Sidekiq.dump_json(msg))
    end
  end
end
