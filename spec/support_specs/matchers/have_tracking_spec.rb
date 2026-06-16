# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/have_tracking.rb', __dir__)

RSpec.describe 'have_tracking matcher', feature_category: :tooling do
  it 'matches when the tracking attributes are present' do
    node = Capybara.string('<a data-track-action="click_link">click</a>')

    expect(node).to have_tracking(action: 'click_link')
  end

  it 'matches when the tracking attributes are absent' do
    node = Capybara.string('<a data-track-action="other_action">click</a>')

    # match_when_negated defines does_not_match? on the matcher
    expect(have_tracking(action: 'click_link')).to respond_to(:does_not_match?)
    expect(node).not_to have_tracking(action: 'click_link')
  end
end
