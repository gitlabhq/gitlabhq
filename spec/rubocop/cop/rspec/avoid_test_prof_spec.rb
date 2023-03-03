# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/rspec/avoid_test_prof'

RSpec.describe RuboCop::Cop::RSpec::AvoidTestProf, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  context 'when there are offenses' do
    where(:method_call, :method_name, :alternatives) do
      'let_it_be(:user)'             | 'let_it_be'             | '`let` or `let!`'
      'let_it_be_with_reload(:user)' | 'let_it_be_with_reload' | '`let` or `let!`'
      'let_it_be_with_refind(:user)' | 'let_it_be_with_refind' | '`let` or `let!`'
      'before_all'                   | 'before_all'            | '`before` or `before(:all)`'
    end

    with_them do
      it 'registers the offense' do
        error_message = "Prefer #{alternatives} over `#{method_name}` in migration specs. " \
                        'See ' \
                        'https://docs.gitlab.com/ee/development/testing_guide/best_practices.html' \
                        '#testprof-in-migration-specs'

        expect_offense(<<~RUBY)
          describe 'foo' do
            #{method_call} { table(:users) }
            #{'^' * method_call.size} #{error_message}
          end
        RUBY
      end
    end
  end

  context 'when there are no offenses' do
    where(method_call: %w[let(:user) let!(:user) before before(:all)])

    with_them do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe 'foo' do
            #{method_call} { table(:users) }
          end
        RUBY
      end
    end
  end
end
