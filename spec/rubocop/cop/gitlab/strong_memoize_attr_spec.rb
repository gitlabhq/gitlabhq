# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/strong_memoize_attr'

RSpec.describe RuboCop::Cop::Gitlab::StrongMemoizeAttr do
  context 'when strong_memoize() is the entire body of a method' do
    context 'when the memoization name is the same as the method name' do
      it 'registers an offense and autocorrects' do
        expect_offense(<<~RUBY)
          class Foo
            def memoized_method
              strong_memoize(:memoized_method) do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `strong_memoize_attr`, instead of using `strong_memoize` directly.
                'This is a memoized method'
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Foo
            def memoized_method
              'This is a memoized method'
            end
            strong_memoize_attr :memoized_method
          end
        RUBY
      end
    end

    context 'when the memoization name is different from the method name' do
      it 'registers an offense and autocorrects' do
        expect_offense(<<~RUBY)
          class Foo
            def enabled?
              strong_memoize(:enabled) do
              ^^^^^^^^^^^^^^^^^^^^^^^^ Use `strong_memoize_attr`, instead of using `strong_memoize` directly.
                true
              end
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Foo
            def enabled?
              true
            end
            strong_memoize_attr :enabled?
          end
        RUBY
      end
    end
  end

  context 'when strong_memoize() is not the entire body of the method' do
    it 'registers an offense and does not autocorrect' do
      expect_offense(<<~RUBY)
        class Foo
          def memoized_method
            msg = 'This is a memoized method'

            strong_memoize(:memoized_method) do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `strong_memoize_attr`, instead of using `strong_memoize` directly.
              msg
            end
          end
        end
      RUBY

      expect_no_corrections
    end
  end

  context 'when strong_memoize() is used in a method with parameters' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def memoized_method(param)
            strong_memoize(:memoized_method) do
              param.to_s
            end
          end
        end
      RUBY
    end
  end

  context 'when strong_memoize() is used in a singleton method' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def self.memoized_method
            strong_memoize(:memoized_method) do
              'this is a memoized method'
            end
          end
        end
      RUBY
    end
  end

  context 'when strong_memoize_with() is called without parameters' do
    it 'registers an offense and autocorrects' do
      expect_offense(<<~RUBY)
        class Foo
          def memoized_method
            strong_memoize_with(:memoized_method) do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `strong_memoize_attr`, instead of using `strong_memoize_with` without parameters.
              'This is a memoized method'
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Foo
          def memoized_method
            'This is a memoized method'
          end
          strong_memoize_attr :memoized_method
        end
      RUBY
    end
  end

  context 'when strong_memoize_with() is called with parameters' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class Foo
          def memoized_method(param)
            strong_memoize_with(:memoized_method, param) do
              param.to_s
            end
          end
        end
      RUBY
    end
  end
end
