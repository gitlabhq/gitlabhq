# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/disallow_current_organization_id_safe_navigation'

RSpec.describe RuboCop::Cop::Gitlab::DisallowCurrentOrganizationIdSafeNavigation, feature_category: :organization do
  include RuboCop::RSpec::ExpectOffense

  let(:hardcoded_expected_message) do
    'Use `Current.organization.id` instead of `Current.organization&.id`. ' \
      '`Current.organization` is expected to be assigned.'
  end

  context 'when `Current.organization&.id` is used' do
    it 'registers an offense and autocorrects `Current.organization&.id`' do
      expect_offense(<<~RUBY)
        id = Current.organization&.id
             ^^^^^^^^^^^^^^^^^^^^^^^^ #{hardcoded_expected_message}
      RUBY

      expect_correction(<<~RUBY)
        id = Current.organization.id
      RUBY
    end

    # This is the test case that was failing due to the spec's conditional logic.
    # Simplify it as follows:
    it 'registers an offense and autocorrects `::Current.organization&.id` (top-level constant)' do
      expect_offense(<<~RUBY)
        id = ::Current.organization&.id
             ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{hardcoded_expected_message}
      RUBY

      expect_correction(<<~RUBY)
        id = ::Current.organization.id
      RUBY
    end

    it 'registers an offense and autocorrects when used in a condition' do
      expect_offense(<<~RUBY)
        if Current.organization&.id == 5
           ^^^^^^^^^^^^^^^^^^^^^^^^ #{hardcoded_expected_message}
        end
      RUBY

      expect_correction(<<~RUBY)
        if Current.organization.id == 5
        end
      RUBY
    end
  end

  context 'when related but non-offending patterns are used' do
    it 'does not register an offense for `Current.organization.id` (no safe navigation)' do
      expect_no_offenses(<<~RUBY)
        id = Current.organization.id
      RUBY
    end

    it 'does not register an offense for `other_object.organization&.id`' do
      expect_no_offenses(<<~RUBY)
        id = other_object.organization&.id
      RUBY
    end

    it 'does not register an offense for `Current.other_method&.id`' do
      expect_no_offenses(<<~RUBY)
        id = Current.other_method&.id
      RUBY
    end

    it 'does not register an offense for `Current.organization&.other_attribute`' do
      expect_no_offenses(<<~RUBY)
        id = Current.organization&.other_attribute
      RUBY
    end

    it 'does not register an offense for just `Current.organization`' do
      expect_no_offenses(<<~RUBY)
        org = Current.organization
      RUBY
    end

    it 'does not register an offense for a different safe navigation chain' do
      expect_no_offenses(<<~RUBY)
        name = Current.user&.name
      RUBY
    end
  end
end
