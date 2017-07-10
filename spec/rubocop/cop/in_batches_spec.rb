require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/in_batches'

describe RuboCop::Cop::InBatches do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'registers an offense when in_batches is used' do
    inspect_source(cop, 'foo.in_batches do; end')

    aggregate_failures do
      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.map(&:line)).to eq([1])
    end
  end
end
