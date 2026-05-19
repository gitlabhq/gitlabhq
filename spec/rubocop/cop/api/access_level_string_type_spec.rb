# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/access_level_string_type'

RSpec.describe RuboCop::Cop::API::AccessLevelStringType, feature_category: :api do
  let(:msg) do
    'Do not use `type: Integer` or `types: [Integer, ...]` for access level parameters. ' \
      'Use `type: String` or a custom type instead to maintain API consistency.'
  end

  context 'when using Integer type for an access level parameter with requires' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, type: Integer, desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for :access_level_execute (prefix)' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level_execute, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for :min_access_level (suffix)' do
      expect_offense(<<~RUBY)
        params do
          requires :min_access_level, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end
  end

  context 'when using Integer type for an access level parameter with optional' do
    it 'adds an offense for :access_level' do
      expect_offense(<<~RUBY)
        params do
          optional :access_level, type: Integer, desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for :push_access_level (suffix)' do
      expect_offense(<<~RUBY)
        params do
          optional :push_access_level, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for :minimum_access_level_execute (mid-name)' do
      expect_offense(<<~RUBY)
        params do
          optional :minimum_access_level_execute, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end
  end

  context 'when using a string parameter name' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        params do
          requires 'access_level', type: Integer, desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end
  end

  context 'when using top-level ::Integer constant' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, type: ::Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end
  end

  context 'when using safe-navigation operator' do
    it 'adds an offense' do
      expect_offense(<<~RUBY)
        params do
          foo&.requires :access_level, type: Integer
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end
  end

  context 'when using types: with Integer in the array' do
    it 'adds an offense for types: [Integer]' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, types: [Integer]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for types: [Integer, String]' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, types: [Integer, String], desc: 'A valid access level'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for types: [String, Integer]' do
      expect_offense(<<~RUBY)
        params do
          optional :access_level, types: [String, Integer]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for types: [::Integer, String]' do
      expect_offense(<<~RUBY)
        params do
          requires :access_level, types: [::Integer, String]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end

    it 'adds an offense for access_level variant names' do
      expect_offense(<<~RUBY)
        params do
          optional :min_access_level, types: [Integer, String]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        end
      RUBY
    end
  end

  context 'when using types: without Integer' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, types: [String]
        end
      RUBY
    end

    it 'does not add an offense for multiple non-Integer types' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, types: [String, CustomType]
        end
      RUBY
    end
  end

  context 'when not an access level parameter' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :per_page, type: Integer, desc: 'Number of items per page'
        end
      RUBY
    end
  end

  context 'when access_level has no type key' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, desc: 'A valid access level'
        end
      RUBY
    end
  end

  context 'when access_level uses a non-Integer type' do
    it 'does not add an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, type: String, desc: 'A valid access level'
        end
      RUBY
    end
  end

  context 'when access_level param has a non-hash second argument' do
    it 'does not add an offense' do
      # This syntax is invalid, so it gets picked up by other cops
      expect_no_offenses(<<~RUBY)
        params do
          requires :access_level, Integer
        end
      RUBY
    end
  end
end
