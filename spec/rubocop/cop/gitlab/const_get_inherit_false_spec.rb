# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/const_get_inherit_false'

describe RuboCop::Cop::Gitlab::ConstGetInheritFalse do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'Object.const_get' do
    it 'registers an offense with no 2nd argument' do
      expect_offense(<<~PATTERN)
        Object.const_get(:CONSTANT)
               ^^^^^^^^^ Use inherit=false when using const_get.
      PATTERN
    end

    it 'autocorrects' do
      expect(autocorrect_source('Object.const_get(:CONSTANT)')).to eq('Object.const_get(:CONSTANT, false)')
    end

    context 'inherit=false' do
      it 'does not register an offense' do
        expect_no_offenses(<<~PATTERN)
        Object.const_get(:CONSTANT, false)
        PATTERN
      end
    end

    context 'inherit=true' do
      it 'registers an offense' do
        expect_offense(<<~PATTERN)
        Object.const_get(:CONSTANT, true)
               ^^^^^^^^^ Use inherit=false when using const_get.
        PATTERN
      end

      it 'autocorrects' do
        expect(autocorrect_source('Object.const_get(:CONSTANT, true)')).to eq('Object.const_get(:CONSTANT, false)')
      end
    end
  end

  context 'const_get for a nested class' do
    it 'registers an offense on reload usage' do
      expect_offense(<<~PATTERN)
        Nested::Blog.const_get(:CONSTANT)
                     ^^^^^^^^^ Use inherit=false when using const_get.
      PATTERN
    end

    it 'autocorrects' do
      expect(autocorrect_source('Nested::Blag.const_get(:CONSTANT)')).to eq('Nested::Blag.const_get(:CONSTANT, false)')
    end

    context 'inherit=false' do
      it 'does not register an offense' do
        expect_no_offenses(<<~PATTERN)
        Nested::Blog.const_get(:CONSTANT, false)
        PATTERN
      end
    end

    context 'inherit=true' do
      it 'registers an offense if inherit is true' do
        expect_offense(<<~PATTERN)
        Nested::Blog.const_get(:CONSTANT, true)
                     ^^^^^^^^^ Use inherit=false when using const_get.
        PATTERN
      end

      it 'autocorrects' do
        expect(autocorrect_source('Nested::Blag.const_get(:CONSTANT, true)')).to eq('Nested::Blag.const_get(:CONSTANT, false)')
      end
    end
  end
end
