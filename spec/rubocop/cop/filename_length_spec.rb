# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/filename_length'

RSpec.describe RuboCop::Cop::FilenameLength do
  it 'does not flag files with names 100 characters long' do
    expect_no_offenses('puts "it does not matter"', 'a' * 100)
  end

  it 'tags files with names 101 characters long' do
    filename = 'a' * 101

    expect_offense(<<~SOURCE, filename)
    source code
    ^ This file name is too long. It should be 100 or less
    SOURCE
  end

  it 'tags files with names 256 characters long' do
    filename = 'a' * 256

    expect_offense(<<~SOURCE, filename)
    source code
    ^ This file name is too long. It should be 100 or less
    SOURCE
  end

  it 'tags files with filepath 256 characters long' do
    filepath = File.join 'a', 'b' * 254

    expect_offense(<<~SOURCE, filepath)
    source code
    ^ This file name is too long. It should be 100 or less
    SOURCE
  end

  it 'tags files with filepath 257 characters long' do
    filepath = File.join 'a', 'b' * 255

    expect_offense(<<~SOURCE, filepath)
    source code
    ^ This file path is too long. It should be 256 or less
    SOURCE
  end
end
