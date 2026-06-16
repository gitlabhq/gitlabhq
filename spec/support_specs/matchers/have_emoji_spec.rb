# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/have_emoji.rb', __dir__)

RSpec.describe 'have_emoji matcher', feature_category: :tooling do
  it 'matches when the emoji is present' do
    node = Capybara.string('<gl-emoji data-name="thumbsup"></gl-emoji>')

    expect(node).to have_emoji('thumbsup')
  end

  it 'matches when the emoji is absent' do
    node = Capybara.string('<gl-emoji data-name="other"></gl-emoji>')

    # match_when_negated defines does_not_match? on the matcher
    expect(have_emoji('thumbsup')).to respond_to(:does_not_match?)
    expect(node).not_to have_emoji('thumbsup')
  end
end
