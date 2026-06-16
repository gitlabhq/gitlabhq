# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/token_without_routable'

RSpec.describe RuboCop::Cop::Gitlab::TokenWithoutRoutable, feature_category: :cell do
  it 'registers offense when routable_token is not provided' do
    expect_offense(<<~RUBY)
      add_authentication_token_field :foobar
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Tokens should be routable. [...]
      add_authentication_token_field :static_object_token, encrypted: :optional
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Tokens should be routable. [...]
      add_authentication_token_field :token,
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Tokens should be routable. [...]
        digest: true
      add_authentication_token_field :foo, routable_token: false
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Tokens should be routable. [...]
      add_authentication_token_field :foo, routable_token: nil
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Tokens should be routable. [...]
    RUBY
  end

  it 'ignores code when routable_token is provided' do
    expect_no_offenses(<<~RUBY)
      add_authentication_token_field :foo, routable_token: { payload: { c: ->(record) { record.cell_id } } }
      add_authentication_token_field :token,
        digest: true,
        routable_token: { payload: { u: ->(record) { record.user_id } } }
      some_other_thing :foo
    RUBY
  end
end
