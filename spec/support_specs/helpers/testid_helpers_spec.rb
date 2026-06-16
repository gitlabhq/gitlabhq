# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'capybara/dsl'

load File.expand_path('../../../spec/support/helpers/testid_helpers.rb', __dir__)

RSpec.describe TestidHelpers, feature_category: :tooling do
  include described_class

  describe '#has_testid?' do
    let(:node) { Capybara.string('<div data-testid="foo">hello</div>') }

    it 'returns true when the testid is present' do
      expect(has_testid?('foo', context: node)).to be true
    end

    it 'returns false when the testid is absent' do
      expect(has_testid?('missing', context: node)).to be false
    end
  end

  describe '#find_by_testid' do
    let(:node) { Capybara.string('<div data-testid="foo">hello</div>') }

    it 'returns the matching element' do
      expect(find_by_testid('foo', context: node).text).to eq('hello')
    end

    it 'raises Capybara::ElementNotFound when the testid is absent' do
      expect { find_by_testid('missing', context: node) }.to raise_error(Capybara::ElementNotFound)
    end
  end

  describe '#all_by_testid' do
    it 'returns all matching elements' do
      node = Capybara.string(
        '<div data-testid="foo">one</div>' \
          '<div data-testid="foo">two</div>'
      )

      expect(all_by_testid('foo', context: node).map(&:text)).to eq(%w[one two])
    end

    it 'returns an empty collection when the testid is absent' do
      node = Capybara.string('<div></div>')

      expect(all_by_testid('missing', context: node)).to be_empty
    end
  end

  describe '#within_testid' do
    # within_testid needs a Capybara::Session - Capybara::Node::Simple does not support #within.
    include Capybara::DSL

    let(:html) do
      '<html><body>' \
        '<div data-testid="container"><span>inside</span></div>' \
        '<span>outside</span>' \
        '</body></html>'
    end

    before do
      Capybara.app = ->(_env) { [200, { 'Content-Type' => 'text/html' }, [html]] }
      visit('/')
    end

    it 'scopes operations to the matching element' do
      within_testid('container') do
        expect(page).to have_content('inside')
        expect(page).not_to have_content('outside')
      end
    end
  end

  describe 'have_no_testid matcher' do
    it 'matches when the testid is absent' do
      node = Capybara.string('<div data-testid="other">hello</div>')

      expect(node).to have_no_testid('missing')
    end
  end
end
