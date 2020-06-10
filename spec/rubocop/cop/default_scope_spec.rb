# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/default_scope'

describe RuboCop::Cop::DefaultScope do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'does not flag the use of default_scope with a send receiver' do
    inspect_source('foo.default_scope')

    expect(cop.offenses.size).to eq(0)
  end

  it 'flags the use of default_scope with a constant receiver' do
    inspect_source('User.default_scope')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of default_scope with a nil receiver' do
    inspect_source('class Foo ; default_scope ; end')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of default_scope when passing arguments' do
    inspect_source('class Foo ; default_scope(:foo) ; end')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of default_scope when passing a block' do
    inspect_source('class Foo ; default_scope { :foo } ; end')

    expect(cop.offenses.size).to eq(1)
  end

  it 'ignores the use of default_scope with a local variable receiver' do
    inspect_source('users = User.all ; users.default_scope')

    expect(cop.offenses.size).to eq(0)
  end
end
