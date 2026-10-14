# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'capybara/dsl'

load File.expand_path('../../../spec/support/matchers/have_current_path_with_normalized_query.rb', __dir__)

RSpec.describe 'have_current_path_with_normalized_query matcher', feature_category: :tooling do
  include Capybara::DSL
  using RSpec::Parameterized::TableSyntax

  before do
    Capybara.app = ->(_env) { [200, { 'Content-Type' => 'text/html' }, ['<html></html>']] }
    visit(visited_path)
  end

  context 'when the current URL is equivalent to the expected URL' do
    where(:visited_path, :expected_url) do
      '/foo'                 | '/foo'
      '/foo?a=b%20c'         | '/foo?a=b+c'
      '/foo?a[]=b'           | '/foo?a%5B%5D=b'
      '/foo?a=b%3A%3Ac'      | '/foo?a=b::c'
      '/foo?a=1&b=2'         | '/foo?b=2&a=1'
      '/foo?a[]=1&b=2&a[]=3' | '/foo?b=2&a[]=1&a[]=3'
      '/foo?a=b'             | 'http://www.example.com/foo?a=b'
    end

    with_them do
      it 'matches' do
        expect(page).to have_current_path_with_normalized_query(expected_url)
      end

      it 'reports both URLs when negated' do
        matcher = have_current_path_with_normalized_query(expected_url)
        matcher.does_not_match?(page)

        expect(matcher.failure_message_when_negated).to eq(
          "expected current URL not to equal #{expected_url.inspect} (normalizing query parameters), " \
            "but got #{page.current_url.inspect}"
        )
      end
    end
  end

  context 'when the current URL differs from the expected URL' do
    where(:visited_path, :expected_url) do
      '/foo?a=1'         | '/bar?a=1'
      '/foo?a=1'         | 'http://other.example.com/foo?a=1'
      '/foo?a=1'         | '/foo?a=2'
      '/foo?a=1'         | '/foo?a=1&b=2'
      '/foo?a=1&b=2'     | '/foo?a=1'
      '/foo?a=1&a=1'     | '/foo?a=1'
      '/foo?a[]=1&a[]=2' | '/foo?a[]=2&a[]=1'
      '/foo?a=b+c'       | '/foo?a=b%2Bc'
    end

    with_them do
      it 'does not match' do
        expect(page).not_to have_current_path_with_normalized_query(expected_url)
      end

      it 'reports both URLs' do
        matcher = have_current_path_with_normalized_query(expected_url)
        matcher.matches?(page)

        expect(matcher.failure_message).to eq(
          "expected current URL to equal #{expected_url.inspect} (normalizing query parameters), " \
            "but got #{page.current_url.inspect}"
        )
      end
    end
  end

  context 'when passing Capybara options' do
    let(:visited_path) { '/foo?a=1' }

    it 'passes them through when matching' do
      expect(page).to receive(:has_current_path?).with('/foo', wait: 5, ignore_query: true).and_call_original

      expect(page).to have_current_path_with_normalized_query('/foo?a=1', wait: 5)
    end

    it 'passes them through when negated' do
      expect(page).to receive(:has_no_current_path?).with('/foo', wait: 5, ignore_query: true).and_call_original

      expect(page).not_to have_current_path_with_normalized_query('/foo?a=2', wait: 5)
    end
  end
end
