# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/destroy_all'

RSpec.describe RuboCop::Cop::DestroyAll do
  it 'flags the use of destroy_all with a send receiver' do
    expect_offense(<<~CODE)
      foo.destroy_all
      ^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    CODE
  end

  it 'flags the use of destroy_all with a constant receiver' do
    expect_offense(<<~CODE)
      User.destroy_all
      ^^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    CODE
  end

  it 'flags the use of destroy_all when passing arguments' do
    expect_offense(<<~CODE)
      User.destroy_all([])
      ^^^^^^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    CODE
  end

  it 'flags the use of destroy_all with a local variable receiver' do
    expect_offense(<<~CODE)
      users = User.all
      users.destroy_all
      ^^^^^^^^^^^^^^^^^ Use `delete_all` instead of `destroy_all`. [...]
    CODE
  end

  it 'does not flag the use of delete_all' do
    expect_no_offenses('foo.delete_all')
  end
end
