# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/avoid_becomes'

RSpec.describe RuboCop::Cop::AvoidBecomes, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of becomes with a constant parameter' do
    inspect_source('foo.becomes(Project)')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of becomes with a namespaced constant parameter' do
    inspect_source('foo.becomes(Namespace::Group)')

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of becomes with a dynamic parameter' do
    inspect_source(<<~RUBY)
    model = Namespace
    project = Project.first
    project.becomes(model)
    RUBY

    expect(cop.offenses.size).to eq(1)
  end
end
