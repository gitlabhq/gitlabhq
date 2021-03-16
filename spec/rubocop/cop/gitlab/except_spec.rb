# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/except'

RSpec.describe RuboCop::Cop::Gitlab::Except do
  subject(:cop) { described_class.new }

  it 'flags the use of Gitlab::SQL::Except.new' do
    expect_offense(<<~SOURCE)
    Gitlab::SQL::Except.new([foo])
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `FromExcept` concern, instead of using `Gitlab::SQL::Except` directly
    SOURCE
  end
end
