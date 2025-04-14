# frozen_string_literal: true

require_relative "helper"

describe Sidekiq::Config do
  before do
    @config = reset!
  end

  it "provides a default size" do
    @config.redis = {}
    assert_equal 10, @config.redis_pool.size
  end

  it "allows custom sizing" do
    @config.redis = {size: 3}
    assert_equal 3, @config.redis_pool.size
  end

  it "keeps #inspect output managable" do
    assert_operator @config.inspect.size, :<, 500
    refute_match(/death_handlers/, @config.inspect)
    refute_match(/error_handlers/, @config.inspect)
  end
end
