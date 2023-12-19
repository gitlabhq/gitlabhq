# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Sidebars::Concerns::ContainerWithHtmlOptions, feature_category: :navigation do
  subject do
    Class.new do
      include Sidebars::Concerns::ContainerWithHtmlOptions

      def title
        'Foo'
      end
    end.new
  end

  describe '#container_html_options' do
    it 'includes by default aria-label attribute' do
      expect(subject.container_html_options).to eq(aria: { label: 'Foo' })
    end
  end
end
