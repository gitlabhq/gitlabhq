# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/code_reuse/finder'

RSpec.describe RuboCop::Cop::CodeReuse::Finder do
  it 'flags the use of a Finder inside another Finder' do
    allow(cop)
      .to receive(:in_finder?)
      .and_return(true)

    expect_offense(<<~RUBY)
      class FooFinder
        def execute
          BarFinder.new.execute
          ^^^^^^^^^^^^^ Finders can not be used inside a Finder.
        end
      end
    RUBY
  end

  it 'flags the use of a Finder inside a model class method' do
    allow(cop)
      .to receive(:in_model?)
      .and_return(true)

    expect_offense(<<~RUBY)
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
    RUBY
  end

  it 'does not flag the use of a Finder in a non Finder file' do
    expect_no_offenses(<<~RUBY)
      class FooFinder
        def execute
          BarFinder.new.execute
        end
      end
    RUBY
  end

  it 'does not flag the use of a Finder in a regular class method' do
    expect_no_offenses(<<~RUBY)
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
    RUBY
  end
end
