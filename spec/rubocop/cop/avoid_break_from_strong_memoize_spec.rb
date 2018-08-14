require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/avoid_break_from_strong_memoize'

describe RuboCop::Cop::AvoidBreakFromStrongMemoize do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags violation for break inside strong_memoize' do
    expect_offense(<<~RUBY)
      strong_memoize(:result) do
        break if something
        ^^^^^ Do not use break inside strong_memoize, use next instead.

        do_an_heavy_calculation
      end
    RUBY
  end

  it 'flags violation for break inside strong_memoize nested blocks' do
    expect_offense(<<~RUBY)
      strong_memoize do
        items.each do |item|
          break item
          ^^^^^^^^^^ Do not use break inside strong_memoize, use next instead.
        end
      end
    RUBY
  end

  it "doesn't flag violation for next inside strong_memoize" do
    expect_no_offenses(<<~RUBY)
      strong_memoize(:result) do
        next if something

        do_an_heavy_calculation
      end
    RUBY
  end

  it "doesn't flag violation for break inside blocks" do
    expect_no_offenses(<<~RUBY)
      call do
        break if something

        do_an_heavy_calculation
      end
    RUBY
  end

  it "doesn't call add_offense twice for nested blocks" do
    source = <<~RUBY
      call do
        strong_memoize(:result) do
          break if something

          do_an_heavy_calculation
        end
      end
    RUBY
    expect_any_instance_of(described_class).to receive(:add_offense).once

    inspect_source(source)
  end

  it "doesn't check when block is empty" do
    expect_no_offenses(<<~RUBY)
      strong_memoize(:result) do
      end
    RUBY
  end
end
