# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require_relative '../../../rubocop/cop/user_admin'

RSpec.describe RuboCop::Cop::UserAdmin do
  subject(:cop) { described_class.new }

  it 'flags a method call' do
    expect_offense(<<~SOURCE)
      user.admin?
           ^^^^^^ #{described_class::MSG}
    SOURCE
  end

  it 'flags a method call with safe operator' do
    expect_offense(<<~SOURCE)
      user&.admin?
            ^^^^^^ #{described_class::MSG}
    SOURCE
  end
end
