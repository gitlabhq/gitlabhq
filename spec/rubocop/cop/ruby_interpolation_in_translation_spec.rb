# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/ruby_interpolation_in_translation'

# Disabling interpolation check as we deliberately want to have #{} in strings.
# rubocop:disable Lint/InterpolationCheck
RSpec.describe RuboCop::Cop::RubyInterpolationInTranslation, type: :rubocop do
  subject(:cop) { described_class.new }

  it 'does not add an offence for a regular messages' do
    inspect_source('_("Hello world")')

    expect(cop.offenses).to be_empty
  end

  it 'adds the correct offence when using interpolation in a string' do
    inspect_source('_("Hello #{world}")')

    offense = cop.offenses.first

    expect(offense.location.source).to eq('#{world}')
    expect(offense.message).to eq('Don\'t use ruby interpolation #{} inside translated strings, instead use %{}')
  end

  it 'detects when using a ruby interpolation in the first argument of a pluralized string' do
    inspect_source('n_("Hello #{world}", "Hello world")')

    expect(cop.offenses).not_to be_empty
  end

  it 'detects when using a ruby interpolation in the second argument of a pluralized string' do
    inspect_source('n_("Hello world", "Hello #{world}")')

    expect(cop.offenses).not_to be_empty
  end

  it 'detects when using interpolation in a namespaced translation' do
    inspect_source('s_("Hello|#{world}")')

    expect(cop.offenses).not_to be_empty
  end

  it 'does not add an offence for messages defined over multiple lines' do
    source = <<~SRC
      _("Hello "\
        "world ")
    SRC

    inspect_source(source)
    expect(cop.offenses).to be_empty
  end

  it 'adds an offence for violations in a message defined over multiple lines' do
    source = <<~SRC
      _("Hello "\
        "\#{world} ")
    SRC

    inspect_source(source)
    expect(cop.offenses).not_to be_empty
  end
end
# rubocop:enable Lint/InterpolationCheck
