# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/ban_catch_throw'

RSpec.describe RuboCop::Cop::BanCatchThrow, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'registers an offense when `catch` or `throw` are used' do
    inspect_source("catch(:foo) {\n  throw(:foo)\n}")

    aggregate_failures do
      expect(cop.offenses.size).to eq(2)
      expect(cop.offenses.map(&:line)).to eq([1, 2])
      expect(cop.highlights).to eq(['catch(:foo)', 'throw(:foo)'])
    end
  end

  it 'does not register an offense for a method called catch or throw' do
    inspect_source("foo.catch(:foo) {\n  foo.throw(:foo)\n}")

    expect(cop.offenses).to be_empty
  end
end
