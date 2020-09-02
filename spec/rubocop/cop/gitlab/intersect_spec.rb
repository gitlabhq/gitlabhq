# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/intersect'

RSpec.describe RuboCop::Cop::Gitlab::Intersect, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of Gitlab::SQL::Intersect.new' do
    expect_offense(<<~SOURCE)
    Gitlab::SQL::Intersect.new([foo])
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `FromIntersect` concern, instead of using `Gitlab::SQL::Intersect` directly
    SOURCE
  end
end
