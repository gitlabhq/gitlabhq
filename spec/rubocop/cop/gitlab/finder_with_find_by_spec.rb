# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/finder_with_find_by'

RSpec.describe RuboCop::Cop::Gitlab::FinderWithFindBy do
  subject(:cop) { described_class.new }

  context 'when calling execute.find' do
    it 'registers an offense and corrects' do
      expect_offense(<<~CODE)
        DummyFinder.new(some_args)
          .execute
          .find_by!(1)
           ^^^^^^^^ Don't chain finders `#execute` method with [...]
      CODE

      expect_correction(<<~CODE)
        DummyFinder.new(some_args)
          .find_by!(1)
      CODE
    end

    context 'when called within the `FinderMethods` module' do
      it 'does not register an offense' do
        expect_no_offenses(<<~SRC)
          module FinderMethods
            def find_by!(*args)
              execute.find_by!(args)
            end
          end
        SRC
      end
    end
  end
end
