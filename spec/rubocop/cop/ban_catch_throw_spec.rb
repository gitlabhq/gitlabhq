# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/ban_catch_throw'

RSpec.describe RuboCop::Cop::BanCatchThrow do
  it 'registers an offense when `catch` or `throw` are used' do
    expect_offense(<<~CODE)
      catch(:foo) {
      ^^^^^^^^^^^ Do not use catch or throw unless a gem's API demands it.
        throw(:foo)
        ^^^^^^^^^^^ Do not use catch or throw unless a gem's API demands it.
      }
    CODE
  end

  it 'does not register an offense for a method called catch or throw' do
    expect_no_offenses(<<~CODE)
      foo.catch(:foo) {
        foo.throw(:foo)
      }
    CODE
  end
end
