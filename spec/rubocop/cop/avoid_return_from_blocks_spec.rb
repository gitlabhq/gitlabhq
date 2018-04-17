require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/avoid_return_from_blocks'

describe RuboCop::Cop::AvoidReturnFromBlocks do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags violation for return inside a block' do
    source = <<~RUBY
      call do
        do_something
        return if something_else
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses.size).to eq(1)
    offense = cop.offenses.first

    expect(offense.line).to eq(3)
    expect(cop.highlights).to eq(['return'])
    expect(offense.message).to eq('Do not return from a block, use next or break instead.')
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
    expect_any_instance_of(described_class).to receive(:add_offense).once

    inspect_source(source)
  end

  it 'flags violation for return inside included > def > block' do
    source = <<~RUBY
      included do
        def a_method
          return if something

          call do
            return if something_else
          end
        end
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses.size).to eq(1)
    offense = cop.offenses.first

    expect(offense.line).to eq(6)
  end

  shared_examples 'examples with whitelisted method' do |whitelisted_method|
    it "doesn't flag violation for return inside #{whitelisted_method}" do
      source = <<~RUBY
        items.#{whitelisted_method} do |item|
          do_something
          return if something_else
        end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end

  %i[each each_filename times loop].each do |whitelisted_method|
    it_behaves_like 'examples with whitelisted method', whitelisted_method
  end

  shared_examples 'examples with def methods' do |def_method|
    it "doesn't flag violation for return inside #{def_method}" do
      source = <<~RUBY
        helpers do
          #{def_method} do
            return if something

            do_something_more
          end
        end
      RUBY
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end

  %i[define_method lambda].each do |def_method|
    it_behaves_like 'examples with def methods', def_method
  end

  it "doesn't flag violation for return inside a lambda" do
    source = <<~RUBY
      lambda do
        do_something
        return if something_else
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses).to be_empty
  end

  it "doesn't flag violation for return used inside a method definition" do
    source = <<~RUBY
      describe Klass do
        def a_method
          do_something
          return if something_else
        end
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses).to be_empty
  end

  it "doesn't flag violation for next inside a block" do
    source = <<~RUBY
      call do
        do_something
        next if something_else
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses).to be_empty
  end

  it "doesn't flag violation for break inside a block" do
    source = <<~RUBY
      call do
        do_something
        break if something_else
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses).to be_empty
  end

  it "doesn't check when block is empty" do
    source = <<~RUBY
      call do
      end
    RUBY
    inspect_source(source)

    expect(cop.offenses).to be_empty
  end
end
