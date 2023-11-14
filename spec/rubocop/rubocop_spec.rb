# frozen_string_literal: true

# No spec helper is `require`d because `fast_spec_helper` requires
# `active_support/all` and we want to ensure that `rubocop/rubocop` loads it.

require 'rubocop'
require_relative '../../rubocop/rubocop'

RSpec.describe 'rubocop/rubocop', feature_category: :tooling do
  it 'loads activesupport to enhance Enumerable' do
    expect(Enumerable.instance_methods).to include(:exclude?)
  end
end
