# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../rubocop/cop/avoid_route_redirect_leading_slash'

RSpec.describe RuboCop::Cop::AvoidRouteRedirectLeadingSlash do
  before do
    allow(cop).to receive(:in_routes?).and_return(true)
  end

  it 'registers an offense when redirect has a leading slash and corrects', :aggregate_failures do
    expect_offense(<<~RUBY)
      root to: redirect("/-/route")
               ^^^^^^^^^^^^^^^^^^^^ Do not use a leading "/" in route redirects
    RUBY

    expect_correction(<<~RUBY)
      root to: redirect("-/route")
    RUBY
  end

  it 'does not register an offense when redirect does not have a leading slash' do
    expect_no_offenses(<<~RUBY)
      root to: redirect("-/route")
    RUBY
  end
end
