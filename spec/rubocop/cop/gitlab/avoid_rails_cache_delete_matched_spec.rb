# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/avoid_rails_cache_delete_matched'

RSpec.describe RuboCop::Cop::Gitlab::AvoidRailsCacheDeleteMatched, feature_category: :tooling do
  it 'flags the use of Rails.cache.delete_matched' do
    expect_offense(<<~RUBY)
      Rails.cache.delete_matched("users/*/feature_enabled/*")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid `Rails.cache.delete_matched` as it scans the entire Redis cluster, causing performance issues and timeouts. Consider using explicit cache key deletion with `Rails.cache.delete` or redesigning the caching strategy.
    RUBY
  end

  it 'flags the use of Rails.cache.delete_matched with a variable pattern' do
    expect_offense(<<~RUBY)
      pattern = "users/*/feature_enabled/*"
      Rails.cache.delete_matched(pattern)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid `Rails.cache.delete_matched` as it scans the entire Redis cluster, causing performance issues and timeouts. Consider using explicit cache key deletion with `Rails.cache.delete` or redesigning the caching strategy.
    RUBY
  end

  it 'flags the use of ::Rails.cache.delete_matched' do
    expect_offense(<<~RUBY)
      ::Rails.cache.delete_matched("some/pattern/*")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid `Rails.cache.delete_matched` as it scans the entire Redis cluster, causing performance issues and timeouts. Consider using explicit cache key deletion with `Rails.cache.delete` or redesigning the caching strategy.
    RUBY
  end

  it 'does not flag the use of Rails.cache.delete' do
    expect_no_offenses(<<~RUBY)
      Rails.cache.delete("users/1/feature_enabled/123")
    RUBY
  end

  it 'does not flag the use of Rails.cache.write' do
    expect_no_offenses(<<~RUBY)
      Rails.cache.write("key", "value")
    RUBY
  end

  it 'does not flag the use of Rails.cache.read' do
    expect_no_offenses(<<~RUBY)
      Rails.cache.read("key")
    RUBY
  end

  it 'does not flag delete_matched on other objects' do
    expect_no_offenses(<<~RUBY)
      custom_cache.delete_matched("pattern")
    RUBY
  end
end
