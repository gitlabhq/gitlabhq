# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/rspec/misspelled_aggregate_failures'

RSpec.describe RuboCop::Cop::RSpec::MisspelledAggregateFailures, feature_category: :shared do
  shared_examples 'misspelled tag' do |misspelled|
    it 'flags and auto-corrects misspelled tags in describe' do
      expect_offense(<<~'RUBY', misspelled: misspelled)
        RSpec.describe 'a feature', :%{misspelled} do
                                    ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
          describe 'inner', :%{misspelled} do
                            ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
          end
        end
      RUBY

      expect_correction(<<~'RUBY')
        RSpec.describe 'a feature', :aggregate_failures do
          describe 'inner', :aggregate_failures do
          end
        end
      RUBY
    end

    it 'flags and auto-corrects misspelled tags in context' do
      expect_offense(<<~'RUBY', misspelled: misspelled)
        context 'a feature', :%{misspelled} do
                             ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
        end
      RUBY

      expect_correction(<<~'RUBY')
        context 'a feature', :aggregate_failures do
        end
      RUBY
    end

    it 'flags and auto-corrects misspelled tags in examples' do
      expect_offense(<<~'RUBY', misspelled: misspelled)
        it 'aggregates', :%{misspelled} do
                         ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
        end

        specify :%{misspelled} do
                ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
        end

        it :%{misspelled} do
           ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
        end
      RUBY

      expect_correction(<<~'RUBY')
        it 'aggregates', :aggregate_failures do
        end

        specify :aggregate_failures do
        end

        it :aggregate_failures do
        end
      RUBY
    end

    it 'flags and auto-corrects misspelled tags in any order' do
      expect_offense(<<~'RUBY', misspelled: misspelled)
        it 'aggregates', :foo, :%{misspelled} do
                               ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
        end

        it 'aggregates', :%{misspelled}, :bar do
                         ^^{misspelled} Use `:aggregate_failures` to aggregate failures.
        end
      RUBY

      expect_correction(<<~'RUBY')
        it 'aggregates', :foo, :aggregate_failures do
        end

        it 'aggregates', :aggregate_failures, :bar do
        end
      RUBY
    end
  end

  shared_examples 'legit tag' do |legit_tag|
    it 'does not flag' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe 'a feature', :#{legit_tag} do
        end

        it 'is ok', :#{legit_tag} do
        end
      RUBY
    end
  end

  context 'with misspelled tags' do
    where(:tag) do
      # From https://gitlab.com/gitlab-org/gitlab/-/issues/396356#list
      %w[
        aggregate_errors
        aggregate_failure
        aggregated_failures
        aggregate_results
        aggregated_errors
        aggregates_failures
        aggregate_failues

        aggregate_bar
        aggregate_foo
      ]
    end

    with_them do
      it_behaves_like 'misspelled tag', params[:tag]
    end
  end

  context 'with legit tags' do
    where(:tag) do
      %w[
        aggregate
        aggregations
        aggregate_two_underscores
      ]
    end

    with_them do
      it_behaves_like 'legit tag', params[:tag]
    end
  end
end
