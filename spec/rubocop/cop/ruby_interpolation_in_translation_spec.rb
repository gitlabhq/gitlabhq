# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../rubocop/cop/ruby_interpolation_in_translation'

# Disabling interpolation check as we deliberately want to have #{} in strings.
# rubocop:disable Lint/InterpolationCheck
RSpec.describe RuboCop::Cop::RubyInterpolationInTranslation do
  let(:msg) { "Don't use ruby interpolation \#{} inside translated strings, instead use %{}" }

  subject(:cop) { described_class.new }

  it 'does not add an offense for a regular messages' do
    expect_no_offenses('_("Hello world")')
  end

  it 'adds the correct offense when using interpolation in a string' do
    expect_offense(<<~CODE)
      _("Hello \#{world}")
                 ^^^^^ #{msg}
               ^^^^^^^^ #{msg}
    CODE
  end

  it 'detects when using a ruby interpolation in the first argument of a pluralized string' do
    expect_offense(<<~CODE)
      n_("Hello \#{world}", "Hello world")
                  ^^^^^ #{msg}
                ^^^^^^^^ #{msg}
    CODE
  end

  it 'detects when using a ruby interpolation in the second argument of a pluralized string' do
    expect_offense(<<~CODE)
      n_("Hello world", "Hello \#{world}")
                                 ^^^^^ #{msg}
                               ^^^^^^^^ #{msg}
    CODE
  end

  it 'detects when using interpolation in a namespaced translation' do
    expect_offense(<<~CODE)
      s_("Hello|\#{world}")
                  ^^^^^ #{msg}
                ^^^^^^^^ #{msg}
    CODE
  end
end
# rubocop:enable Lint/InterpolationCheck
