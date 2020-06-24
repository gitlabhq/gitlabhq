# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/code_reuse/finder'

RSpec.describe RuboCop::Cop::CodeReuse::Finder, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of a Finder inside another Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class FooFinder
        def execute
          BarFinder.new.execute
          ^^^^^^^^^^^^^ Finders can not be used inside a Finder.
        end
      end
    SOURCE

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of a Finder inside a model class method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~SOURCE)
      class User
        class << self
          def second_method
            BarFinder.new
            ^^^^^^^^^^^^^ Finders can not be used inside model class methods.
          end
        end

        def self.second_method
          FooFinder.new
          ^^^^^^^^^^^^^ Finders can not be used inside model class methods.
        end
      end
    SOURCE
  end

  it 'does not flag the use of a Finder in a non Finder file' do
    expect_no_offenses(<<~SOURCE)
      class FooFinder
        def execute
          BarFinder.new.execute
        end
      end
    SOURCE
  end

  it 'does not flag the use of a Finder in a regular class method' do
    expect_no_offenses(<<~SOURCE)
      class User
        class << self
          def second_method
            BarFinder.new
          end
        end

        def self.second_method
          FooFinder.new
        end
      end
    SOURCE
  end
end
