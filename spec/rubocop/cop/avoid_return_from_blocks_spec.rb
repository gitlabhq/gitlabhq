# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/avoid_return_from_blocks'

describe RuboCop::Cop::AvoidReturnFromBlocks do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags violation for return inside a block' do
    expect_offense(<<~RUBY)
      call do
        do_something
        return if something_else
        ^^^^^^ Do not return from a block, use next or break instead.
      end
    RUBY
  end

  it "doesn't call add_offense twice for nested blocks" do
    source = <<~RUBY
      call do
        call do
          something
          return if something_else
        end
      end
    RUBY
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:add_offense).once
    end

    inspect_source(source)
  end

  it 'flags violation for return inside included > def > block' do
    expect_offense(<<~RUBY)
      included do
        def a_method
          return if something

          call do
            return if something_else
            ^^^^^^ Do not return from a block, use next or break instead.
          end
        end
      end
    RUBY
  end

  shared_examples 'examples with whitelisted method' do |whitelisted_method|
    it "doesn't flag violation for return inside #{whitelisted_method}" do
      expect_no_offenses(<<~RUBY)
        items.#{whitelisted_method} do |item|
          do_something
          return if something_else
        end
      RUBY
    end
  end

  %i[each each_filename times loop].each do |whitelisted_method|
    it_behaves_like 'examples with whitelisted method', whitelisted_method
  end

  shared_examples 'examples with def methods' do |def_method|
    it "doesn't flag violation for return inside #{def_method}" do
      expect_no_offenses(<<~RUBY)
        helpers do
          #{def_method} do
            return if something

            do_something_more
          end
        end
      RUBY
    end
  end

  %i[define_method lambda].each do |def_method|
    it_behaves_like 'examples with def methods', def_method
  end

  it "doesn't flag violation for return inside a lambda" do
    expect_no_offenses(<<~RUBY)
      lambda do
        do_something
        return if something_else
      end
    RUBY
  end

  it "doesn't flag violation for return used inside a method definition" do
    expect_no_offenses(<<~RUBY)
      describe Klass do
        def a_method
          do_something
          return if something_else
        end
      end
    RUBY
  end

  it "doesn't flag violation for next inside a block" do
    expect_no_offenses(<<~RUBY)
      call do
        do_something
        next if something_else
      end
    RUBY
  end

  it "doesn't flag violation for break inside a block" do
    expect_no_offenses(<<~RUBY)
      call do
        do_something
        break if something_else
      end
    RUBY
  end

  it "doesn't check when block is empty" do
    expect_no_offenses(<<~RUBY)
      call do
      end
    RUBY
  end
end
