# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/rspec/missing_match_when_negated'

RSpec.describe RuboCop::Cop::RSpec::MissingMatchWhenNegated, feature_category: :tooling do
  it 'flags a matcher that wraps `expect(...).to have_selector` without `match_when_negated`' do
    expect_offense(<<~RUBY)
      RSpec::Matchers.define :have_testid do |testid|
        match do |actual|
        ^^^^^ Custom matcher uses Capybara DOM queries in `match` but does not define `match_when_negated`. `not_to` against this matcher falls back to negating `match` and waits the full Capybara timeout. Define `match_when_negated` using the negative-waiting counterpart (e.g., `has_no_selector?`).
          expect(actual).to have_selector("[data-testid='\#{testid}']")
        end
      end
    RUBY
  end

  it 'flags a matcher that uses `has_selector?` predicate without `match_when_negated`' do
    expect_offense(<<~RUBY)
      RSpec::Matchers.define :have_testid do |testid|
        match do |actual|
        ^^^^^ Custom matcher uses Capybara DOM queries in `match` but does not define `match_when_negated`. `not_to` against this matcher falls back to negating `match` and waits the full Capybara timeout. Define `match_when_negated` using the negative-waiting counterpart (e.g., `has_no_selector?`).
          actual.has_selector?("[data-testid='\#{testid}']")
        end
      end
    RUBY
  end

  it 'flags a matcher that uses `find_by_testid` without `match_when_negated`' do
    expect_offense(<<~RUBY)
      RSpec::Matchers.define :show_thing do
        match do |actual|
        ^^^^^ Custom matcher uses Capybara DOM queries in `match` but does not define `match_when_negated`. `not_to` against this matcher falls back to negating `match` and waits the full Capybara timeout. Define `match_when_negated` using the negative-waiting counterpart (e.g., `has_no_selector?`).
          find_by_testid('thing')
        end
      end
    RUBY
  end

  it 'flags a Capybara query nested inside another block within `match`' do
    expect_offense(<<~RUBY)
      RSpec::Matchers.define :foo do
        match do |actual|
        ^^^^^ Custom matcher uses Capybara DOM queries in `match` but does not define `match_when_negated`. `not_to` against this matcher falls back to negating `match` and waits the full Capybara timeout. Define `match_when_negated` using the negative-waiting counterpart (e.g., `has_no_selector?`).
          actual.each do |item|
            expect(item).to have_text('hi')
          end
        end
      end
    RUBY
  end

  it 'flags a matcher using numbered block parameters' do
    expect_offense(<<~RUBY)
      RSpec::Matchers.define :have_testid do |testid|
        match do
        ^^^^^ Custom matcher uses Capybara DOM queries in `match` but does not define `match_when_negated`. `not_to` against this matcher falls back to negating `match` and waits the full Capybara timeout. Define `match_when_negated` using the negative-waiting counterpart (e.g., `has_no_selector?`).
          _1.has_selector?("[data-testid='\#{testid}']")
        end
      end
    RUBY
  end

  it 'does not flag when `match_when_negated` is defined' do
    expect_no_offenses(<<~RUBY)
      RSpec::Matchers.define :have_testid do |testid|
        match do |actual|
          actual.has_selector?("[data-testid='\#{testid}']")
        end

        match_when_negated do |actual|
          actual.has_no_selector?("[data-testid='\#{testid}']")
        end
      end
    RUBY
  end

  it 'does not flag matchers that do not touch the DOM (e.g., mock expectations)' do
    expect_no_offenses(<<~RUBY)
      RSpec::Matchers.define :execute_check do |expected|
        match do |actual|
          expect(actual).to receive(:run)
        end
      end
    RUBY
  end

  it 'does not flag matchers that only use non-Capybara matchers' do
    expect_no_offenses(<<~RUBY)
      RSpec::Matchers.define :be_a_thing do
        match do |actual|
          expect(actual).to be_a(Thing)
        end
      end
    RUBY
  end

  it 'does not flag `define_negated_matcher`' do
    expect_no_offenses(<<~RUBY)
      RSpec::Matchers.define_negated_matcher :have_no_foo, :have_foo
    RUBY
  end

  it 'does not flag unrelated `match` blocks (e.g., String#match)' do
    expect_no_offenses(<<~RUBY)
      "hello".match(/h/) do |m|
        expect(m).to be_present
      end
    RUBY
  end

  it 'does not flag matchers without a `match` block' do
    expect_no_offenses(<<~RUBY)
      RSpec::Matchers.define :foo do
        failure_message { 'nope' }
      end
    RUBY
  end
end
