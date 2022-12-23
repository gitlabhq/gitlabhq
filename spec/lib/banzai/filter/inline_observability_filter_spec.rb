# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineObservabilityFilter do
  include FilterSpecHelper

  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  describe '#filter?' do
    context 'when the document has an external link' do
      let(:url) { 'https://foo.com' }

      it 'leaves regular non-observability links unchanged' do
        expect(doc.to_s).to eq(input)
      end
    end

    context 'when the document contains an embeddable observability link' do
      let(:url) { 'https://observe.gitlab.com/12345' }

      it 'leaves the original link unchanged' do
        expect(doc.at_css('a').to_s).to eq(input)
      end

      it 'appends an observability charts placeholder' do
        node = doc.at_css('.js-render-observability')

        expect(node).to be_present
        expect(node.attribute('data-frame-url').to_s).to eq(url)
      end
    end

    context 'when feature flag is disabled' do
      let(:url) { 'https://observe.gitlab.com/12345' }

      before do
        stub_feature_flags(observability_group_tab: false)
      end

      it 'leaves the original link unchanged' do
        expect(doc.at_css('a').to_s).to eq(input)
      end

      it 'does not append an observability charts placeholder' do
        node = doc.at_css('.js-render-observability')

        expect(node).not_to be_present
      end
    end
  end
end
