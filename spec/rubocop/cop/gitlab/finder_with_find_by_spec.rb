# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/finder_with_find_by'

RSpec.describe RuboCop::Cop::Gitlab::FinderWithFindBy do
  context 'when calling execute.find' do
    it 'registers an offense and corrects' do
      expect_offense(<<~RUBY)
        DummyFinder.new(some_args)
          .execute
          .find_by!(1)
           ^^^^^^^^ Don't chain finders `#execute` method with [...]
      RUBY

      expect_correction(<<~RUBY)
        DummyFinder.new(some_args)
          .find_by!(1)
      RUBY
    end

    context 'when called within the `FinderMethods` module' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          module FinderMethods
            def find_by!(*args)
              execute.find_by!(args)
            end
          end
        RUBY
      end
    end
  end
end
