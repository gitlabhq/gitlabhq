# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/direct_stdio'

RSpec.describe RuboCop::Cop::Gitlab::DirectStdio, feature_category: :tooling do
  it 'flags $stdout.puts' do
    expect_offense(<<~RUBY)
      $stdout.puts('hello')
      ^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags $stdout.print' do
    expect_offense(<<~RUBY)
      $stdout.print('hello')
      ^^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags $stderr.puts' do
    expect_offense(<<~RUBY)
      $stderr.puts('hello')
      ^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags $stderr.print' do
    expect_offense(<<~RUBY)
      $stderr.print('hello')
      ^^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags STDOUT.puts' do
    expect_offense(<<~RUBY)
      STDOUT.puts('hello')
      ^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags STDOUT.print' do
    expect_offense(<<~RUBY)
      STDOUT.print('hello')
      ^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags STDERR.puts' do
    expect_offense(<<~RUBY)
      STDERR.puts('hello')
      ^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'flags STDERR.print' do
    expect_offense(<<~RUBY)
      STDERR.print('hello')
      ^^^^^^^^^^^^^^^^^^^^^ [...]
    RUBY
  end

  it 'does not flag bare puts (handled by Rails/Output)' do
    expect_no_offenses("puts 'hello'")
  end

  it 'does not flag $stdout.write' do
    expect_no_offenses("$stdout.write('hello')")
  end

  it 'does not flag logger.info' do
    expect_no_offenses("logger.info('hello')")
  end

  it 'does not flag puts on an arbitrary IO object' do
    expect_no_offenses("some_io.puts('hello')")
  end
end
