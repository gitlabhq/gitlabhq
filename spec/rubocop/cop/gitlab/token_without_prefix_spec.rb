# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/token_without_prefix'

RSpec.describe RuboCop::Cop::Gitlab::TokenWithoutPrefix, feature_category: :secret_detection do
  let(:msg) { described_class::MSG }

  it 'registers offense for single predicate method with allow_nil:true' do
    expect_offense(<<~SOURCE)
      add_authentication_token_field :foobar
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      add_authentication_token_field :static_object_token, encrypted: :optional
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
      add_authentication_token_field :token,
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg}
        digest: true
    SOURCE
  end

  it 'ignores code when prefix is provided' do
    expect_no_offenses(<<~RUBY)
      add_authentication_token_field :foo, format_with_prefix: :bar
      add_authentication_token_field :token,
        digest: true,
        format_with_prefix: :prefix_from_application_current_settings
      some_other_thing :foo
    RUBY
  end
end
