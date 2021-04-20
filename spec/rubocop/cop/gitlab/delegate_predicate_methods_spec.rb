# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/delegate_predicate_methods'

RSpec.describe RuboCop::Cop::Gitlab::DelegatePredicateMethods do
  subject(:cop) { described_class.new }

  it 'registers offense for single predicate method with allow_nil:true' do
    expect_offense(<<~SOURCE)
      delegate :is_foo?, :do_foo, to: :bar, allow_nil: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `delegate` with `allow_nil` on the following predicate methods is discouraged: is_foo?.
    SOURCE
  end

  it 'registers offense for multiple predicate methods with allow_nil:true' do
    expect_offense(<<~SOURCE)
      delegate :is_foo?, :is_bar?, to: :bar, allow_nil: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `delegate` with `allow_nil` on the following predicate methods is discouraged: is_foo?, is_bar?.
    SOURCE
  end

  it 'registers no offense for non-predicate method with allow_nil:true' do
    expect_no_offenses(<<~SOURCE)
      delegate :do_foo, to: :bar, allow_nil: true
    SOURCE
  end

  it 'registers no offense with predicate method with allow_nil:false' do
    expect_no_offenses(<<~SOURCE)
      delegate :is_foo?, to: :bar, allow_nil: false
    SOURCE
  end

  it 'registers no offense with predicate method without allow_nil' do
    expect_no_offenses(<<~SOURCE)
      delegate :is_foo?, to: :bar
    SOURCE
  end
end
