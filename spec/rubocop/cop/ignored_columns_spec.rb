# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../rubocop/cop/ignored_columns'

describe RuboCop::Cop::IgnoredColumns do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of destroy_all with a local variable receiver' do
    inspect_source(<<~RUBY)
      class Foo < ApplicationRecord
        self.ignored_columns += %i[id]
      end
    RUBY

    expect(cop.offenses.size).to eq(1)
  end
end
