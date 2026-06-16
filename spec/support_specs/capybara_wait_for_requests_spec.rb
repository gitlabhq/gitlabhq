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
end
