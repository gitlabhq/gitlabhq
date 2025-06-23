# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/destroy_all'

RSpec.describe RuboCop::Cop::DestroyAll do
  it 'flags the use of destroy_all with a send receiver' do
    expect_offense(<<~RUBY)
      foo.destroy_all
      ^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    RUBY
  end

  it 'flags the use of destroy_all with a constant receiver' do
    expect_offense(<<~RUBY)
      User.destroy_all
      ^^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    RUBY
  end

  it 'flags the use of destroy_all when passing arguments' do
    expect_offense(<<~RUBY)
      User.destroy_all([])
      ^^^^^^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    RUBY
  end

  it 'flags the use of destroy_all with a local variable receiver' do
    expect_offense(<<~RUBY)
      users = User.all
      users.destroy_all
      ^^^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    RUBY
  end

  it 'does not flag the use of delete_all' do
    expect_no_offenses('foo.delete_all')
  end
end
