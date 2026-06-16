# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'

load File.expand_path('../../../spec/support/matchers/navigation_matcher.rb', __dir__)

RSpec.describe 'navigation matchers', feature_category: :tooling do
  describe 'have_active_navigation' do
    it 'matches when the navigation entry is active' do
      node = Capybara.string(
        '<div data-testid="super-sidebar">' \
          '<button aria-expanded="true">Foo</button>' \
          '</div>'
      )

      expect(node).to have_active_navigation('Foo')
    end

    it 'matches when the navigation entry is not active' do
      node = Capybara.string(
        '<div data-testid="super-sidebar">' \
          '<button aria-expanded="false">Foo</button>' \
          '</div>'
      )

      # match_when_negated defines does_not_match? on the matcher
      expect(have_active_navigation('Foo')).to respond_to(:does_not_match?)
      expect(node).not_to have_active_navigation('Foo')
    end
  end

  describe 'have_active_sub_navigation' do
    it 'matches when the sub-navigation entry is active' do
      node = Capybara.string(
        '<div data-testid="super-sidebar">' \
          '<a aria-current="page">Foo</a>' \
          '</div>'
      )

      expect(node).to have_active_sub_navigation('Foo')
    end

    it 'matches when the sub-navigation entry is not active' do
      node = Capybara.string(
        '<div data-testid="super-sidebar">' \
          '<a>Foo</a>' \
          '</div>'
      )

      # match_when_negated defines does_not_match? on the matcher
      expect(have_active_sub_navigation('Foo')).to respond_to(:does_not_match?)
      expect(node).not_to have_active_sub_navigation('Foo')
    end
  end
end
