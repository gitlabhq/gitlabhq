# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/avoid_keyword_arguments_in_sidekiq_workers'

describe RuboCop::Cop::AvoidKeywordArgumentsInSidekiqWorkers do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags violation for keyword arguments usage in perform method signature' do
    expect_offense(<<~RUBY)
      def perform(id:)
      ^^^^^^^^^^^^^^^^ Do not use keyword arguments in Sidekiq workers. For details, check https://github.com/mperham/sidekiq/issues/2372
      end
    RUBY
  end

  it 'flags violation for optional keyword arguments usage in perform method signature' do
    expect_offense(<<~RUBY)
      def perform(id: nil)
      ^^^^^^^^^^^^^^^^^^^^ Do not use keyword arguments in Sidekiq workers. For details, check https://github.com/mperham/sidekiq/issues/2372
      end
    RUBY
  end

  it 'does not flag a violation for standard optional arguments usage in perform method signature' do
    expect_no_offenses(<<~RUBY)
      def perform(id = nil)
      end
    RUBY
  end

  it 'does not flag a violation for keyword arguments usage in non-perform method signatures' do
    expect_no_offenses(<<~RUBY)
      def helper(id:)
      end
    RUBY
  end

  it 'does not flag a violation for optional keyword arguments usage in non-perform method signatures' do
    expect_no_offenses(<<~RUBY)
      def helper(id: nil)
      end
    RUBY
  end
end
