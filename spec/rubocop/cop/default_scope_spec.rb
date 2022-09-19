# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/default_scope'

RSpec.describe RuboCop::Cop::DefaultScope do
  it 'does not flag the use of default_scope with a send receiver' do
    expect_no_offenses('foo.default_scope')
  end

  it 'flags the use of default_scope with a constant receiver' do
    expect_offense(<<~SOURCE)
      User.default_scope
      ^^^^^^^^^^^^^^^^^^ Do not use `default_scope`, [...]
    SOURCE
  end

  it 'flags the use of default_scope with a nil receiver' do
    expect_offense(<<~SOURCE)
      class Foo ; default_scope ; end
                  ^^^^^^^^^^^^^ Do not use `default_scope`, [...]
    SOURCE
  end

  it 'flags the use of default_scope when passing arguments' do
    expect_offense(<<~SOURCE)
      class Foo ; default_scope(:foo) ; end
                  ^^^^^^^^^^^^^^^^^^^ Do not use `default_scope`, [...]
    SOURCE
  end

  it 'flags the use of default_scope when passing a block' do
    expect_offense(<<~SOURCE)
      class Foo ; default_scope { :foo } ; end
                  ^^^^^^^^^^^^^ Do not use `default_scope`, [...]
    SOURCE
  end

  it 'ignores the use of default_scope with a local variable receiver' do
    expect_no_offenses('users = User.all ; users.default_scope')
  end
end
