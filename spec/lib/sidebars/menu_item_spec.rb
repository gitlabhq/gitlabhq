# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::MenuItem do
  let(:title) { 'foo' }
  let(:html_options) { {} }
  let(:menu_item) { described_class.new(title: title, active_routes: {}, link: '', container_html_options: html_options) }

  it 'includes by default aria-label attribute set to the title' do
    expect(menu_item.container_html_options).to eq({ aria: { label: title } })
  end

  context 'when aria-label is overridde during initialization' do
    let(:html_options) { { aria: { label: 'bar' } } }

    it 'sets the aria-label to the new attribute' do
      expect(menu_item.container_html_options).to eq html_options
    end
  end
end
