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
end
