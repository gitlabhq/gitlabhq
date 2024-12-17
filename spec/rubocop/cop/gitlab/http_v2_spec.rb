# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/http_v2'

RSpec.describe RuboCop::Cop::Gitlab::HttpV2, feature_category: :shared do
  it 'flags the use of `Gitlab::HTTP_V2`' do
    expect_offense(<<~RUBY)
      Gitlab::HTTP_V2.get('https://gitlab.com')
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid calling `Gitlab::HTTP_V2` directly [...]
    RUBY
  end

  it 'flags the use of `Gitlab::HTTP_V2` with multiple arguments' do
    expect_offense(<<~RUBY)
      Gitlab::HTTP_V2.get('https://gitlab.com', headers: { 'Content-Type' => 'application/json' })
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid calling `Gitlab::HTTP_V2` directly [...]
    RUBY
  end

  it 'flags the use of `Gitlab::HTTP_V2` with multiple arguments and a block' do
    expect_offense(<<~RUBY)
      Gitlab::HTTP_V2.get('https://gitlab.com', headers: { 'Content-Type' => 'application/json' }) do |req|
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid calling `Gitlab::HTTP_V2` directly [...]
      end
    RUBY
  end

  it 'does not flag the use of `Gitlab::HTTP_V2::UrlBlocker.validate!' do
    expect_no_offenses(<<~RUBY)
      Gitlab::HTTP_V2::UrlBlocker.validate!('https://gitlab.com')
    RUBY
  end

  it 'does not flag the use of `Gitlab::HTTP.get`' do
    expect_no_offenses(<<~RUBY)
      Gitlab::HTTP.get('https://gitlab.com')
    RUBY
  end
end
