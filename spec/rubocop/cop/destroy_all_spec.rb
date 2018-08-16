require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/destroy_all'

describe RuboCop::Cop::DestroyAll do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of destroy_all with a send receiver' do
    inspect_source('foo.destroy_all')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of destroy_all with a constant receiver' do
    inspect_source('User.destroy_all')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of destroy_all when passing arguments' do
    inspect_source('User.destroy_all([])')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of destroy_all with a local variable receiver' do
    inspect_source(<<~RUBY)
    users = User.all
    users.destroy_all
    RUBY

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not flag the use of delete_all' do
    inspect_source('foo.delete_all')

    expect(cop.offenses).to be_empty
  end
end
