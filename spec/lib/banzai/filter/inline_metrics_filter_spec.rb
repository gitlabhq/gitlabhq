# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::InlineMetricsFilter do
  include FilterSpecHelper

  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  context 'when the document has an external link' do
    let(:url) { 'https://foo.com' }

    it 'leaves regular non-metrics links unchanged' do
      expect(doc.to_s).to eq input
    end
  end

  context 'when the document has a metrics dashboard link' do
    let(:params) { ['foo', 'bar', 12] }
    let(:url) { urls.metrics_namespace_project_environment_url(*params) }

    it 'leaves the original link unchanged' do
      expect(doc.at_css('a').to_s).to eq input
    end

    it 'appends a metrics charts placeholder with dashboard url after metrics links' do
      node = doc.at_css('.js-render-metrics')
      expect(node).to be_present

      dashboard_url = urls.metrics_dashboard_namespace_project_environment_url(*params, embedded: true)
      expect(node.attribute('data-dashboard-url').to_s).to eq dashboard_url
    end

    context 'when the metrics dashboard link is part of a paragraph' do
      let(:paragraph) { %(This is an <a href="#{url}">example</a> of metrics.) }
      let(:input) { %(<p>#{paragraph}</p>) }

      it 'appends the charts placeholder after the enclosing paragraph' do
        expect(doc.at_css('p').to_s).to include paragraph
        expect(doc.at_css('.js-render-metrics')).to be_present
      end
    end
  end
end
