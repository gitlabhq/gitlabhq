# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'support/capybara_wait_for_all_requests'

RSpec.describe 'capybara_wait_for_all_requests', feature_category: :tooling do # rubocop:disable RSpec/FilePath
  context 'for Capybara::Session::WaitForAllRequestsAfterVisitPage' do
    let(:page_visitor) do
      Class.new do
        def visit(visit_uri)
          visit_uri
        end

        prepend Capybara::Session::WaitForAllRequestsAfterVisitPage
      end.new
    end

    it 'waits for all requests after a page visit' do
      expect(page_visitor).to receive(:wait_for_all_requests)

      page_visitor.visit('http://test.com')
    end
  end

  context 'for Capybara::Node::Actions::WaitForAllRequestsAfterClickButton' do
    let(:node) do
      Class.new do
        def click_button(locator = nil, **_options)
          locator
        end

        prepend Capybara::Node::Actions::WaitForAllRequestsAfterClickButton
      end.new
    end

    it 'waits for all requests after a click button' do
      expect(node).to receive(:wait_for_all_requests)

      node.click_button
    end
  end

  context 'for Capybara::Node::Actions::WaitForAllRequestsAfterClickLink' do
    let(:node) do
      Class.new do
        def click_link(locator = nil, **_options)
          locator
        end

        prepend Capybara::Node::Actions::WaitForAllRequestsAfterClickLink
      end.new
    end

    it 'waits for all requests after a click link' do
      expect(node).to receive(:wait_for_all_requests)

      node.click_link
    end
  end
end
