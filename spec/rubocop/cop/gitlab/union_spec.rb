# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/union'

RSpec.describe RuboCop::Cop::Gitlab::Union, feature_category: :database do
  it 'flags the use of Gitlab::SQL::Union.new' do
    expect_offense(<<~RUBY)
    Gitlab::SQL::Union.new([foo])
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use the `FromUnion` concern, instead of using `Gitlab::SQL::Union` directly
    RUBY
  end
end
