# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/union'

RSpec.describe RuboCop::Cop::Gitlab::Union, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of Gitlab::SQL::Union.new' do
    expect_offense(<<~SOURCE)
    Gitlab::SQL::Union.new([foo])
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `FromUnion` concern, instead of using `Gitlab::SQL::Union` directly
    SOURCE
  end
end
