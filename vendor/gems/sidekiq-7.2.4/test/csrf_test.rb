# frozen_string_literal: true

require_relative "helper"
require "sidekiq/web/csrf_protection"

describe "Csrf" do
  def session
    @session ||= {}
  end

  def env(method = :get, form_hash = {}, rack_session = session)
    imp = StringIO.new
    {
      "REQUEST_METHOD" => method.to_s.upcase,
      "rack.session" => rack_session,
      "rack.logger" => ::Logger.new(@logio ||= StringIO.new),
      "rack.input" => imp,
      "rack.request.form_input" => imp,
      "rack.request.form_hash" => form_hash
    }
  end

  def call(env, &block)
    Sidekiq::Web::CsrfProtection.new(block).call(env)
  end

  it "get" do
    ok = [200, {}, ["OK"]]
    first = 1
    second = 1
    result = call(env) do |envy|
      refute_nil envy[:csrf_token]
      assert_equal 88, envy[:csrf_token].size
      first = envy[:csrf_token]
      ok
    end
    assert_equal ok, result

    result = call(env) do |envy|
      refute_nil envy[:csrf_token]
      assert_equal 88, envy[:csrf_token].size
      second = envy[:csrf_token]
      ok
    end
    assert_equal ok, result

    # verify masked token changes on every valid request
    refute_equal first, second
  end

  it "bad post" do
    result = call(env(:post)) do
      raise "Shouldn't be called"
    end
    refute_nil result
    assert_equal 403, result[0]
    assert_equal ["Forbidden"], result[2]

    @logio.rewind
    assert_match(/attack prevented/, @logio.string)
  end

  it "succeeds with good token" do
    # Make a GET to set up the session with a good token
    goodtoken = call(env) do |envy|
      envy[:csrf_token]
    end
    assert goodtoken

    # Make a POST with the known good token
    result = call(env(:post, "authenticity_token" => goodtoken)) do
      [200, {}, ["OK"]]
    end
    refute_nil result
    assert_equal 200, result[0]
    assert_equal ["OK"], result[2]
  end

  it "fails with bad token" do
    # Make a POST with a known bad token
    result = call(env(:post, "authenticity_token" => "N0QRBD34tU61d7fi+0ZaF/35JLW/9K+8kk8dc1TZoK/0pTl7GIHap5gy7BWGsoKlzbMLRp1yaDpCDFwTJtxWAg==")) do
      raise "shouldn't be called"
    end
    refute_nil result
    assert_equal 403, result[0]
    assert_equal ["Forbidden"], result[2]
  end

  it "empty session post" do
    # Make a GET to set up the session with a good token
    goodtoken = call(env) do |envy|
      envy[:csrf_token]
    end
    assert goodtoken

    # Make a POST with an empty session data and good token
    result = call(env(:post, {"authenticity_token" => goodtoken}, {})) do
      raise "shouldn't be called"
    end
    refute_nil result
    assert_equal 403, result[0]
    assert_equal ["Forbidden"], result[2]
  end

  it "empty csrf session post" do
    # Make a GET to set up the session with a good token
    goodtoken = call(env) do |envy|
      envy[:csrf_token]
    end
    assert goodtoken

    # Make a POST without csrf session data and good token
    result = call(env(:post, {"authenticity_token" => goodtoken}, {"session_id" => "foo"})) do
      raise "shouldn't be called"
    end
    refute_nil result
    assert_equal 403, result[0]
    assert_equal ["Forbidden"], result[2]
  end
end
