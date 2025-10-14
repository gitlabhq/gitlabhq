# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/saas_feature_available_outside_ee'

RSpec.describe RuboCop::Cop::Gitlab::SaasFeatureAvailableOutsideEe, feature_category: :shared do
  let(:msg) { 'Gitlab::Saas.feature_available? should only be used within the /ee directory.' }

  it 'registers an offense for Gitlab::Saas.feature_available?' do
    expect_offense(<<~RUBY)
      if Gitlab::Saas.feature_available?(:some_feature)
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} [...]
        do_something
      end
    RUBY
  end

  it 'registers an offense for ::Gitlab::Saas.feature_available?' do
    expect_offense(<<~RUBY)
      return unless ::Gitlab::Saas.feature_available?(:feature)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} [...]
    RUBY
  end

  it 'registers an offense for Gitlab::Saas&.feature_available?' do
    expect_offense(<<~RUBY)
      return unless Gitlab::Saas&.feature_available?(:feature)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} [...]
    RUBY
  end

  it 'registers an offense for ::Gitlab::Saas&.feature_available?' do
    expect_offense(<<~RUBY)
      return unless ::Gitlab::Saas&.feature_available?(:feature)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} [...]
    RUBY
  end

  it 'does not register an offense for other methods' do
    expect_no_offenses(<<~RUBY)
      Gitlab::Saas.enabled?
      Gitlab.com?
      feature_available?(:some_feature)
    RUBY
  end
end
