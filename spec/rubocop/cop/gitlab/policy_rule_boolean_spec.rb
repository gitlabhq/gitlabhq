# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/policy_rule_boolean'

RSpec.describe RuboCop::Cop::Gitlab::PolicyRuleBoolean do
  it 'registers offense for &&' do
    expect_offense(<<~RUBY)
      rule { conducts_electricity && batteries }.enable :light_bulb
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ && is not allowed within a rule block. Did you mean to use `&`?
    RUBY
  end

  it 'registers offense for ||' do
    expect_offense(<<~RUBY)
      rule { conducts_electricity || batteries }.enable :light_bulb
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ || is not allowed within a rule block. Did you mean to use `|`?
    RUBY
  end

  it 'registers offense for if' do
    expect_offense(<<~RUBY)
      rule { if conducts_electricity then can?(:magnetize) else batteries end }.enable :motor
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ if and ternary operators are not allowed within a rule block.
    RUBY
  end

  it 'registers offense for ternary operator' do
    expect_offense(<<~RUBY)
      rule { conducts_electricity ? can?(:magnetize) : batteries }.enable :motor
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ if and ternary operators are not allowed within a rule block.
    RUBY
  end

  it 'registers no offense for &' do
    expect_no_offenses(<<~RUBY)
      rule { conducts_electricity & batteries }.enable :light_bulb
    RUBY
  end

  it 'registers no offense for |' do
    expect_no_offenses(<<~RUBY)
      rule { conducts_electricity | batteries }.enable :light_bulb
    RUBY
  end
end
