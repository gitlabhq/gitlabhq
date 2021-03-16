# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/safe_params'

RSpec.describe RuboCop::Cop::SafeParams do
  subject(:cop) { described_class.new }

  it 'flags the params as an argument of url_for' do
    expect_offense(<<~SOURCE)
      url_for(params)
      ^^^^^^^^^^^^^^^ Use `safe_params` instead of `params` in url_for.
    SOURCE
  end

  it 'flags the merged params as an argument of url_for' do
    expect_offense(<<~SOURCE)
      url_for(params.merge(additional_params))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `safe_params` instead of `params` in url_for.
    SOURCE
  end

  it 'flags the merged params arg as an argument of url_for' do
    expect_offense(<<~SOURCE)
      url_for(something.merge(additional).merge(params))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `safe_params` instead of `params` in url_for.
    SOURCE
  end

  it 'does not flag other argument of url_for' do
    expect_no_offenses(<<~SOURCE)
      url_for(something)
    SOURCE
  end
end
