# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/avoid_route_redirect_leading_slash'

RSpec.describe RuboCop::Cop::AvoidRouteRedirectLeadingSlash do
  subject(:cop) { described_class.new }

  before do
    allow(cop).to receive(:in_routes?).and_return(true)
  end

  it 'registers an offense when redirect has a leading slash and corrects', :aggregate_failures do
    expect_offense(<<~PATTERN)
      root to: redirect("/-/route")
               ^^^^^^^^^^^^^^^^^^^^ Do not use a leading "/" in route redirects
    PATTERN

    expect_correction(<<~PATTERN)
      root to: redirect("-/route")
    PATTERN
  end

  it 'does not register an offense when redirect does not have a leading slash' do
    expect_no_offenses(<<~PATTERN)
      root to: redirect("-/route")
    PATTERN
  end
end
