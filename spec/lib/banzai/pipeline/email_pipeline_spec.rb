# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::EmailPipeline, feature_category: :markdown do
  describe '.filters' do
    it_behaves_like 'sanitize pipeline'

    it 'returns the expected type' do
      expect(described_class.filters).to be_kind_of(Banzai::FilterArray)
    end

    it 'excludes ImageLazyLoadFilter' do
      expect(described_class.filters).not_to be_empty
      expect(described_class.filters).not_to include(Banzai::Filter::ImageLazyLoadFilter)
    end

    it 'shows punycode for autolinks' do
      examples = %W[
        http://one😄two.com
        http://\u0261itlab.com
      ]

      examples.each do |markdown|
        result = described_class.call(markdown, project: nil)[:output]
        link   = result.css('a').first

        expect(link.content).to include('http://xn--')
      end
    end
  end

  describe '.transform_context' do
    it 'marks the render as being for email' do
      expect(described_class.transform_context({})).to include(for_email: true)
    end
  end
end
