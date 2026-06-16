# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/have_work_item_count.rb', __dir__)

RSpec.describe 'have_work_item_count matcher', feature_category: :tooling do
  it 'matches when the count is correct' do
    node = Capybara.string(
      '<div data-testid="issuable-container"></div>' \
        '<div data-testid="issuable-container"></div>' \
        '<div data-testid="issuable-container"></div>'
    )

    expect(node).to have_work_item_count(3)
  end

  it 'matches the negation when the count differs' do
    node = Capybara.string(
      '<div data-testid="issuable-container"></div>' \
        '<div data-testid="issuable-container"></div>'
    )

    # match_when_negated defines does_not_match? on the matcher
    expect(have_work_item_count(3)).to respond_to(:does_not_match?)
    expect(node).not_to have_work_item_count(3)
  end
end
