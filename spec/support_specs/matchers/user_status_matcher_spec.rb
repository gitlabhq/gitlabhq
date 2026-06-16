# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/user_status_matcher.rb', __dir__)

RSpec.describe 'show_user_status matcher', feature_category: :tooling do
  let(:status) { Struct.new(:message, :emoji).new('BBQ', 'thumbsup') }

  it 'matches when the status emoji is present' do
    node = Capybara.string(
      '<span class="user-status-emoji" title="BBQ">' \
        '<gl-emoji data-name="thumbsup"></gl-emoji>' \
        '</span>'
    )

    expect(node).to show_user_status(status)
  end

  it 'matches when the status emoji is absent' do
    node = Capybara.string('<span class="user-status-emoji" title="Other"></span>')

    # match_when_negated defines does_not_match? on the matcher
    expect(show_user_status(status)).to respond_to(:does_not_match?)
    expect(node).not_to show_user_status(status)
  end
end
