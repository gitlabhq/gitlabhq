# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/have_testid.rb', __dir__)

RSpec.describe 'have_testid matcher', feature_category: :tooling do
  it 'matches when the testid is present' do
    node = Capybara.string('<div data-testid="foo">hello</div>')

    expect(node).to have_testid('foo')
  end

  it 'matches when the testid is absent' do
    node = Capybara.string('<div data-testid="other">hello</div>')

    # match_when_negated defines does_not_match? on the matcher
    expect(have_testid('missing')).to respond_to(:does_not_match?)
    expect(node).not_to have_testid('missing')
  end
end
