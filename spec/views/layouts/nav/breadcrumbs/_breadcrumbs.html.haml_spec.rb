# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'layouts/nav/breadcrumbs/_breadcrumbs', feature_category: :navigation do
  describe 'element for Vue page breadcrumbs' do
    context 'when the page has breadcrumbs' do
      let(:expected_json) do
        [
          { text: "Foo", href: "http://test.host/foo", avatarPath: nil },
          { text: "Bar", href: "http://test.host/foo/bar", avatarPath: nil }
        ].to_json
      end

      before do
        assign(:header_title, 'Foo')
        assign(:header_title_url, 'http://test.host/foo')
        assign(:breadcrumb_title, 'Bar')
        assign(:breadcrumb_link, 'http://test.host/foo/bar')
      end

      it 'has the correct data attribute value' do
        render
        expect(rendered).to have_selector("#js-vue-page-breadcrumbs[data-breadcrumbs-json='#{expected_json}']")
      end
    end

    context 'when the page has no breadcrumbs' do
      let(:expected_json) { [].to_json }

      before do
        assign(:skip_current_level_breadcrumb, true)
      end

      it 'still renders the element with an empty array as data attribute value' do
        render
        expect(rendered).to have_selector("#js-vue-page-breadcrumbs[data-breadcrumbs-json='#{expected_json}']")
      end
    end
  end
end
