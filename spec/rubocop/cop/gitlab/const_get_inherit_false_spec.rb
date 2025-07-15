# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/const_get_inherit_false'

RSpec.describe RuboCop::Cop::Gitlab::ConstGetInheritFalse do
  context 'Object.const_get' do
    it 'registers an offense with no 2nd argument and corrects' do
      expect_offense(<<~RUBY)
        Object.const_get(:CONSTANT)
               ^^^^^^^^^ Use inherit=false when using const_get.
      RUBY

      expect_correction(<<~RUBY)
        Object.const_get(:CONSTANT, false)
      RUBY
    end

    context 'inherit=false' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          Object.const_get(:CONSTANT, false)
        RUBY
      end
    end

    context 'inherit=true' do
      it 'registers an offense and corrects' do
        expect_offense(<<~RUBY)
          Object.const_get(:CONSTANT, true)
                 ^^^^^^^^^ Use inherit=false when using const_get.
        RUBY

        expect_correction(<<~RUBY)
          Object.const_get(:CONSTANT, false)
        RUBY
      end
    end
  end

  context 'const_get for a nested class' do
    it 'registers an offense on reload usage and corrects' do
      expect_offense(<<~RUBY)
        Nested::Blog.const_get(:CONSTANT)
                     ^^^^^^^^^ Use inherit=false when using const_get.
      RUBY

      expect_correction(<<~RUBY)
        Nested::Blog.const_get(:CONSTANT, false)
      RUBY
    end

    context 'inherit=false' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          Nested::Blog.const_get(:CONSTANT, false)
        RUBY
      end
    end

    context 'inherit=true' do
      it 'registers an offense if inherit is true and corrects' do
        expect_offense(<<~RUBY)
          Nested::Blog.const_get(:CONSTANT, true)
                       ^^^^^^^^^ Use inherit=false when using const_get.
        RUBY

        expect_correction(<<~RUBY)
          Nested::Blog.const_get(:CONSTANT, false)
        RUBY
      end
    end
  end
end
