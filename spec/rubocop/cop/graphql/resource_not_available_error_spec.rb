# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/graphql/resource_not_available_error'

RSpec.describe RuboCop::Cop::Graphql::ResourceNotAvailableError, feature_category: :shared do
  shared_examples 'flagging and auto-correction' do |exception|
    it "flags and auto-corrects `raise #{exception}`" do
      expect_offense(<<~'RUBY', exception: exception)
        raise %{exception}
        ^^^^^^^{exception} Prefer using `raise_resource_not_available_error!` instead.

        raise %{exception}, 'message ' \
        ^^^^^^^{exception}^^^^^^^^^^^^^^ Prefer using `raise_resource_not_available_error!` instead.
          'with new lines'
      RUBY

      expect_correction(<<~'RUBY')
        raise_resource_not_available_error!

        raise_resource_not_available_error! 'message ' \
          'with new lines'
      RUBY
    end
  end

  it_behaves_like 'flagging and auto-correction', 'Gitlab::Graphql::Errors::ResourceNotAvailable'
  it_behaves_like 'flagging and auto-correction', '::Gitlab::Graphql::Errors::ResourceNotAvailable'

  it 'does not flag unrelated exceptions' do
    expect_no_offenses(<<~RUBY)
      raise Gitlab::Graphql::Errors::ResourceVeryAvailable
      raise ::Gitlab::Graphql::Errors::ResourceVeryAvailable
    RUBY
  end
end
