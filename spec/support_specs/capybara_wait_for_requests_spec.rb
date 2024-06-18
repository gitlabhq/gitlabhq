# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'support/capybara_wait_for_requests'

RSpec.describe 'capybara_wait_for_requests', feature_category: :tooling do
  context 'for Capybara::Session::WaitForRequestsAfterVisitPage' do
    let(:page_visitor) do
      Class.new do
        def visit(visit_uri)
          visit_uri
        end

        prepend Capybara::Session::WaitForRequestsAfterVisitPage
      end.new
    end

    it 'waits for requests after a page visit' do
      expect(page_visitor).to receive(:wait_for_requests)

      page_visitor.visit('http://test.com')
    end
  end

  context 'for Capybara::Node::Actions::WaitForRequestsAfterClickButton' do
    let(:node) do
      Class.new do
        def click_button(locator = nil, **_options)
          locator
        end

        prepend Capybara::Node::Actions::WaitForRequestsAfterClickButton
      end.new
    end

    it 'waits for requests after a click button' do
      expect(node).to receive(:wait_for_requests)

      node.click_button
    end
  end

  context 'for Capybara::Node::Actions::WaitForRequestsAfterClickLink' do
    let(:node) do
      Class.new do
        def click_link(locator = nil, **_options)
          locator
        end

        prepend Capybara::Node::Actions::WaitForRequestsAfterClickLink
      end.new
    end

    it 'waits for requests after a click link' do
      expect(node).to receive(:wait_for_requests)

      node.click_link
    end
  end
end
