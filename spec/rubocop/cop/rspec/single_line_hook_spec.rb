require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/single_line_hook'

describe RuboCop::Cop::RSpec::SingleLineHook do
  include CopHelper

  subject(:cop) { described_class.new }

  # Override `CopHelper#inspect_source` to always appear to be in a spec file,
  # so that our RSpec-only cop actually runs
  def inspect_source(*args)
    super(*args, 'foo_spec.rb')
  end

  it 'registers an offense for a single-line `before` block' do
    inspect_source(cop, 'before { do_something }')

    expect(cop.offenses.size).to eq(1)
    expect(cop.offenses.map(&:line)).to eq([1])
    expect(cop.highlights).to eq(['before { do_something }'])
  end

  it 'registers an offense for a single-line `after` block' do
    inspect_source(cop, 'after(:each) { undo_something }')

    expect(cop.offenses.size).to eq(1)
    expect(cop.offenses.map(&:line)).to eq([1])
    expect(cop.highlights).to eq(['after(:each) { undo_something }'])
  end

  it 'registers an offense for a single-line `around` block' do
    inspect_source(cop, 'around { |ex| do_something_else }')

    expect(cop.offenses.size).to eq(1)
    expect(cop.offenses.map(&:line)).to eq([1])
    expect(cop.highlights).to eq(['around { |ex| do_something_else }'])
  end

  it 'ignores a multi-line `before` block' do
    inspect_source(cop, ['before do',
                         '  do_something',
                         'end'])

    expect(cop.offenses.size).to eq(0)
  end

  it 'ignores a multi-line `after` block' do
    inspect_source(cop, ['after(:each) do',
                         '  undo_something',
                         'end'])

    expect(cop.offenses.size).to eq(0)
  end

  it 'ignores a multi-line `around` block' do
    inspect_source(cop, ['around do |ex|',
                         '  do_something_else',
                         'end'])

    expect(cop.offenses.size).to eq(0)
  end
end
