# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/active_model_errors_direct_manipulation'

RSpec.describe RuboCop::Cop::ActiveModelErrorsDirectManipulation do
  context 'when modifying errors' do
    it 'registers an offense' do
      expect_offense(<<~PATTERN)
        user.errors[:name] << 'msg'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid manipulating errors hash directly. [...]
      PATTERN
    end

    context 'when assigning' do
      it 'registers an offense' do
        expect_offense(<<~PATTERN)
        user.errors[:name] = []
        ^^^^^^^^^^^^^^^^^^^^^^^ Avoid manipulating errors hash directly. [...]
        PATTERN
      end
    end
  end

  context 'when modifying errors.messages' do
    it 'registers an offense' do
      expect_offense(<<~PATTERN)
        user.errors.messages[:name] << 'msg'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid manipulating errors hash directly. [...]
      PATTERN
    end

    context 'when assigning' do
      it 'registers an offense' do
        expect_offense(<<~PATTERN)
        user.errors.messages[:name] = []
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid manipulating errors hash directly. [...]
        PATTERN
      end
    end
  end

  context 'when modifying errors.details' do
    it 'registers an offense' do
      expect_offense(<<~PATTERN)
        user.errors.details[:name] << {}
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid manipulating errors hash directly. [...]
      PATTERN
    end

    context 'when assigning' do
      it 'registers an offense' do
        expect_offense(<<~PATTERN)
        user.errors.details[:name] = []
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid manipulating errors hash directly. [...]
        PATTERN
      end
    end
  end
end
