# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/have_issuable_counts.rb', __dir__)

RSpec.describe 'have_issuable_counts matcher', feature_category: :tooling do
  it 'matches when all expected counts are present' do
    node = Capybara.string('<div class="top-area">Open 5 Closed 3</div>')

    expect(node).to have_issuable_counts(open: 5, closed: 3)
  end

  it 'matches when none of the expected counts are present' do
    node = Capybara.string('<div class="top-area">Open 10 Closed 7</div>')

    # match_when_negated defines does_not_match? on the matcher
    expect(have_issuable_counts(open: 5, closed: 3)).to respond_to(:does_not_match?)
    expect(node).not_to have_issuable_counts(open: 5, closed: 3)
  end
end
