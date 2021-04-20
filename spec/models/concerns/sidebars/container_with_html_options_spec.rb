# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::ContainerWithHtmlOptions do
  subject do
    Class.new do
      include Sidebars::ContainerWithHtmlOptions

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
