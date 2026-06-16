# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'capybara/dsl'

load File.expand_path('../../../spec/support/matchers/have_current_path_ignoring_trailing_slash.rb', __dir__)

RSpec.describe 'have_current_path_ignoring_trailing_slash matcher', feature_category: :tooling do
  include Capybara::DSL

  before do
    Capybara.app = ->(_env) { [200, { 'Content-Type' => 'text/html' }, ['<html></html>']] }
    visit('/foo')
  end

  it 'matches both the bare path and the path with a trailing slash' do
    expect(page).to have_current_path_ignoring_trailing_slash('/foo')
    expect(page).to have_current_path_ignoring_trailing_slash('/foo/')
  end

  it 'matches when the path does not match' do
    # match_when_negated defines does_not_match? on the matcher
    expect(have_current_path_ignoring_trailing_slash('/foo')).to respond_to(:does_not_match?)
    expect(page).not_to have_current_path_ignoring_trailing_slash('/bar')
  end
end
