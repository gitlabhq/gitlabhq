# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/ignored_columns'

RSpec.describe RuboCop::Cop::IgnoredColumns do
  subject(:cop) { described_class.new }

  it 'flags direct use of ignored_columns instead of the IgnoredColumns concern' do
    expect_offense(<<~RUBY)
      class Foo < ApplicationRecord
        self.ignored_columns += %i[id]
        ^^^^^^^^^^^^^^^^^^^^ Use `IgnoredColumns` concern instead of adding to `self.ignored_columns`.
      end
    RUBY
  end
end
