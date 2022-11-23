# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/user_admin'

RSpec.describe RuboCop::Cop::UserAdmin do
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
