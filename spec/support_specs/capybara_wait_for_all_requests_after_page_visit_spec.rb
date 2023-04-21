# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'support/capybara_wait_for_all_requests_after_visit_page'

RSpec.describe Capybara::Session::WaitForAllRequestsAfterVisitPage, feature_category: :tooling do # rubocop:disable RSpec/FilePath
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
