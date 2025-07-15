# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/delegate_predicate_methods'

RSpec.describe RuboCop::Cop::Gitlab::DelegatePredicateMethods do
  it 'registers offense for single predicate method with allow_nil:true' do
    expect_offense(<<~RUBY)
      delegate :is_foo?, :do_foo, to: :bar, allow_nil: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `delegate` with `allow_nil` on the following predicate methods is discouraged: is_foo?.
    RUBY
  end

  it 'registers offense for multiple predicate methods with allow_nil:true' do
    expect_offense(<<~RUBY)
      delegate :is_foo?, :is_bar?, to: :bar, allow_nil: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `delegate` with `allow_nil` on the following predicate methods is discouraged: is_foo?, is_bar?.
    RUBY
  end

  it 'registers no offense for non-predicate method with allow_nil:true' do
    expect_no_offenses(<<~RUBY)
      delegate :do_foo, to: :bar, allow_nil: true
    RUBY
  end

  it 'registers no offense with predicate method with allow_nil:false' do
    expect_no_offenses(<<~RUBY)
      delegate :is_foo?, to: :bar, allow_nil: false
    RUBY
  end

  it 'registers no offense with predicate method without allow_nil' do
    expect_no_offenses(<<~RUBY)
      delegate :is_foo?, to: :bar
    RUBY
  end
end
